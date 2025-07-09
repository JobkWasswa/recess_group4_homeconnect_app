// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp(); // Initialize Firebase Admin SDk

/**
 * Callable Cloud Function to get recommended service providers.
 *
 * @param {object} data - The data passed from the client (Flutter app).
 * @param {string} data.serviceCategory - The category of service requested.
 * @param {number} data.homeownerLatitude - Latitude of the homeowner's job location.
 * @param {number} data.homeownerLongitude - Longitude of the homeowner's job location.
 * @param {string} [data.desiredDateTime] - Optional: ISO string of the desired date and time for service.
 *
 * @param {object} context - The context of the function call (includes auth info).
 * @returns {object} An object containing a 'providers' array of recommended service providers.
 */
exports.getRecommendedProviders = functions.https.onCall(
  async (data, context) => {
    // MODIFICATION: Removed strict authentication check.
    // The function will now proceed whether or not context.auth is present.
    // You can still access context.auth.uid if you need the user's ID for personalization
    // const userId = context.auth ? context.auth.uid : null;
    // console.log(`Invoking getRecommendedProviders for user: ${userId || 'Unauthenticated'}`);

    // Input Validation: Ensure required parameters are provided.
    const {
      serviceCategory,
      homeownerLatitude,
      homeownerLongitude,
      desiredDateTime, // This will be used for availability filtering
    } = data;

    if (
      !serviceCategory ||
      typeof homeownerLatitude !== "number" ||
      typeof homeownerLongitude !== "number"
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing or invalid required parameters (serviceCategory, homeownerLatitude, homeownerLongitude)."
      );
    }

    const homeownerLocation = {
      latitude: homeownerLatitude,
      longitude: homeownerLongitude,
    };
    const MAX_DISTANCE_KM = 7; // Your defined maximum radius for matching

    console.log(
      `Searching for '${serviceCategory}' providers near (${homeownerLatitude}, ${homeownerLongitude})`
    );

    let providersSnapshot;
    try {
      // Step 1: Initial query from Firestore based on serviceCategory
      providersSnapshot = await admin
        .firestore()
        .collection("service_providers")
        .where("categories", "array-contains", serviceCategory)
        .get();

      if (providersSnapshot.empty) {
        console.log("No service providers found for this category.");
        return { providers: [] };
      }
    } catch (error) {
      console.error("Error fetching initial providers from Firestore:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to retrieve service providers data.",
        error.message
      );
    }

    const eligibleProviders = [];

    // Loop through each provider to apply filtering and scoring
    for (const doc of providersSnapshot.docs) {
      const providerData = doc.data();
      const providerId = doc.id;
      console.log(`Processing provider: ${providerId}`);

      let meetsAllCriteria = true;

      // --- Geospatial Filtering Logic ---
      let distance = null;
      // Accessing location correctly (assuming it's a GeoPoint field directly in Firestore)
      if (
        !providerData.location ||
        typeof providerData.location.latitude === "undefined" ||
        typeof providerData.location.longitude === "undefined"
      ) {
        console.warn(
          `Provider ${providerId} is missing complete location data. Skipping.`
        );
        meetsAllCriteria = false;
      } else {
        const providerBaseLocation = {
          latitude: providerData.location.latitude,
          longitude: providerData.location.longitude,
        };

        distance = calculateDistance(
          homeownerLocation.latitude,
          homeownerLocation.longitude,
          providerBaseLocation.latitude,
          providerBaseLocation.longitude
        ); // Distance in kilometers

        // Filter: Check if provider's base location is within the MAX_DISTANCE_KM (7km) from homeowner
        if (distance > MAX_DISTANCE_KM) {
          console.log(
            `Provider ${providerId} too far (${distance.toFixed(
              2
            )} km). Skipping.`
          );
          meetsAllCriteria = false;
        }
      }
      // --- End of Geospatial Filtering Logic ---

      // --- Availability Filtering Logic ---
      // This part assumes a simple 'availableToday' boolean in your Firestore document.
      // If desiredDateTime is provided, we check against 'availableToday'.
      // If desiredDateTime is NOT provided, and provider has 'availableToday' set to false, filter it out.
      if (meetsAllCriteria) {
        const providerAvailableToday = providerData.availableToday ?? true; // Default to true if field is missing

        if (desiredDateTime) {
          // If a specific date/time is requested, enforce 'availableToday' or more complex logic
          if (!providerAvailableToday) {
            console.log(
              `Provider ${providerId} not available on specified date. Skipping.`
            );
            meetsAllCriteria = false;
          }
          // TODO: Implement more sophisticated date/time availability parsing if needed
          // e.g., using a library like 'luxon' or 'moment-timezone' to check against `providerData.availability` map
          // based on `desiredDateTime`.
        } else {
          // If no specific date/time requested, just filter by 'availableToday' if it's explicitly false
          if (!providerAvailableToday) {
            console.log(
              `Provider ${providerId} not generally available today. Skipping.`
            );
            meetsAllCriteria = false;
          }
        }
      }

      // If all hard filters are met, add to eligible list for scoring/ranking
      if (meetsAllCriteria) {
        // --- Rating & Review Scoring ---
        // CORRECTED: Access averageRating and numberOfReviews directly from providerData
        const rating = providerData.averageRating ?? 0;
        const reviewCount = providerData.numberOfReviews ?? 0;
        const score = calculateRatingScore(rating, reviewCount, distance); // Pass distance for a proximity bonus

        eligibleProviders.push({
          id: providerId,
          // CORRECTED: Access name directly from providerData (as per screenshot)
          name: providerData.name ?? "Unnamed Provider",
          profilePhoto: providerData.profilePhoto ?? null,
          categories: providerData.categories ?? [],
          availableToday: providerData.availableToday ?? false,
          service: serviceCategory, // Or the actual services offered by the provider
          rating: rating,
          reviewCount: reviewCount,
          distanceKm:
            distance !== null ? parseFloat(distance.toFixed(2)) : null, // Ensure 'distanceKm' matches model
          score: score,
          // Add any other data needed by the Flutter UI here
        });
      }
    }

    // --- Overall Ranking Logic ---
    // Sort by the calculated score (highest score first).
    eligibleProviders.sort((a, b) => b.score - a.score);

    console.log(`Found ${eligibleProviders.length} eligible providers.`);
    return { providers: eligibleProviders };
  }
);

// Helper Function: Distance Calculation (Haversine Formula)
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radius of Earth in kilometers
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c; // Distance in km
  return distance;
}

// Helper Function: Rating Score Calculation (Refined)
function calculateRatingScore(averageRating, reviewCount, distanceKm) {
  // A more refined scoring function:
  // 1. Base score from average rating.
  // 2. Bonus for more reviews (more reliable rating).
  // 3. Penalty for distance (closer providers are preferred).

  if (reviewCount === 0) return 0; // Providers with no reviews get a base score of 0, or some minimal value.

  let score = averageRating;

  // Add a bonus for review count. The more reviews, the more trustworthy the rating.
  // This example gives a small boost for every 10 reviews, up to a certain point.
  score += Math.min(reviewCount * 0.05, 1.0); // Max 1.0 point bonus for 20+ reviews

  // Apply a distance penalty. Closer is better.
  // Example: 0.1 point penalty per km, up to a maximum penalty.
  if (distanceKm !== null && distanceKm !== undefined) {
    score -= Math.min(distanceKm * 0.1, 2.0); // Max 2.0 point penalty for 20+ km
  }

  return Math.max(0, score); // Ensure score doesn't go below zero
}

// Helper Function: Availability Check (This is a placeholder and needs real implementation)
/*
function isAvailableOnDate(providerSchedule, desiredDate) {
    // providerSchedule: This would be the complex data structure from Firestore,
    // e.g., { 'Monday': ['9:00-17:00'], 'holidays': ['2025-12-25'] }
    // desiredDate: A JavaScript Date object derived from desiredDateTime ISO string.

    // Example rudimentary logic:
    // 1. Check if desiredDate falls on a holiday or blocked date.
    // 2. Check if desiredDate's day of the week is in their schedule.
    // 3. If desiredDateTime includes a specific time, check if that time slot is open.

    // For simplicity, returning true. You will expand this significantly.
    console.log(`Checking availability for a specific date/time for provider... (Not fully implemented yet)`);
    return true;
}
*/
