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
    // Basic Authentication Check: Ensure the user is authenticated.
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

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
        // Ensure this field name 'categories' or 'servicesOffered' matches your Firestore schema
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
        // Removed the providerServiceRadius check as requested
      }
      // --- End of Geospatial Filtering Logic ---

      // --- Availability Filtering Logic (Implement based on your Firestore structure) ---
      // This is a crucial part and depends heavily on how you store availability.
      // For now, let's use a simple 'availableToday' boolean if present.
      // If you implement a complex schedule, this function needs to parse it.
      if (meetsAllCriteria && desiredDateTime) {
        const providerAvailableToday = providerData.availableToday ?? false; // Assuming a boolean field
        // More sophisticated availability check would go here, e.g.,
        // const requestedDate = new Date(desiredDateTime);
        // if (!isAvailableOnDate(providerData.schedule, requestedDate)) {
        //   meetsAllCriteria = false;
        // }

        // For this example, let's just use the 'availableToday' flag for simplicity
        if (!providerAvailableToday) {
          console.log(`Provider ${providerId} not available today. Skipping.`);
          meetsAllCriteria = false;
        }
      } else if (meetsAllCriteria && desiredDateTime === undefined) {
        // If no desiredDateTime is provided by client, and provider has availableToday field, filter by it.
        // If a provider doesn't have an 'availableToday' field, assume they are available
        const providerAvailableToday = providerData.availableToday ?? true;
        if (!providerAvailableToday) {
          console.log(`Provider ${providerId} not available today. Skipping.`);
          meetsAllCriteria = false;
        }
      }

      // If all hard filters are met, add to eligible list for scoring/ranking
      if (meetsAllCriteria) {
        // --- Rating & Review Scoring ---
        const rating = providerData.ratings?.average ?? 0;
        const reviewCount = providerData.ratings?.count ?? 0;
        const score = calculateRatingScore(rating, reviewCount, distance); // Pass distance for a proximity bonus

        eligibleProviders.push({
          id: providerId,
          name: providerData.profileInfo?.name ?? "Unnamed Provider",
          profilePhoto: providerData.profilePhoto ?? null,
          categories: providerData.categories ?? [],
          availableToday: providerData.availableToday ?? false,
          service: serviceCategory,
          rating: rating,
          reviewCount: reviewCount,
          distance: distance ? parseFloat(distance.toFixed(2)) : null,
          score: score,
          // Add any other data needed by the Flutter UI here
          // e.g., contactInfo, full address, etc.
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
