const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp(); // Initialize Firebase Admin SDK

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
      desiredDateTime,
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
      // This will fetch all providers offering this service, before further filtering.
      providersSnapshot = await admin
        .firestore()
        .collection("service_providers")
        .where("servicesOffered", "array-contains", serviceCategory)
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

      // Placeholder for filtering logic
      let meetsAllCriteria = true; // Assume true initially, set to false if any criteria fails

      // --- Start of Geospatial Filtering Logic ---
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

        const distance = calculateDistance(
          homeownerLocation.latitude,
          homeownerLocation.longitude,
          providerBaseLocation.latitude,
          providerBaseLocation.longitude
        ); // Distance in kilometers

        // Filter 1: Check if provider's base location is within the MAX_DISTANCE_KM (7km) from homeowner
        if (distance > MAX_DISTANCE_KM) {
          console.log(
            `Provider ${providerId} too far (${distance.toFixed(
              2
            )} km). Skipping.`
          );
          meetsAllCriteria = false;
        } else {
          // Filter 2 (Optional but good): Check if homeowner's location is within provider's declared service radius
          // This means the provider must *also* declare they cover the homeowner's area.
          const providerServiceRadius = providerData.serviceRadius || 0; // Default to 0 if not set in Firestore
          if (distance > providerServiceRadius && providerServiceRadius > 0) {
            console.log(
              `Provider ${providerId} (radius ${providerServiceRadius}km) doesn't cover this distance ${distance.toFixed(
                2
              )}km. Skipping.`
            );
            meetsAllCriteria = false;
          }
        }
      }
      // --- End of Geospatial Filtering Logic ---

      // --- Placeholder for Availability Filtering (Your next step) ---
      // if (meetsAllCriteria && desiredDateTime) {
      //     const isProviderAvailable = checkAvailability(providerData.availability, desiredDateTime);
      //     if (!isProviderAvailable) {
      //         meetsAllCriteria = false;
      //     }
      // }

      // If all hard filters are met, add to eligible list for scoring/ranking
      if (meetsAllCriteria) {
        // --- Placeholder for Rating & Review Scoring (Your next step) ---
        const rating = providerData.ratings?.average ?? 0;
        const reviewCount = providerData.ratings?.count ?? 0;
        const score = calculateRatingScore(rating, reviewCount); // You'll implement this helper

        eligibleProviders.push({
          id: providerId,
          name: providerData.profileInfo?.name, // Assuming you have this structure
          service: serviceCategory,
          rating: rating,
          reviewCount: reviewCount,
          distance: parseFloat(distance.toFixed(2)), // Ensure distance is defined here
          score: score,
          // Add any other data needed by the Flutter UI here
        });
      }
    }

    // --- Overall Ranking Logic ---
    // Sort by the calculated score (highest score first).
    // If scores are equal, you might add secondary sort criteria (e.g., jobs completed, creation date).
    eligibleProviders.sort((a, b) => b.score - a.score);

    console.log(`Found ${eligibleProviders.length} eligible providers.`);
    return { providers: eligibleProviders };
  }
);

// Helper Function: Distance Calculation (Haversine Formula)
// Place this function outside (below) the main Cloud Function or in a separate utility file.
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

// Helper Function: Rating Score Calculation (Implement this next)
function calculateRatingScore(averageRating, reviewCount) {
  // For now, a very simple score. You'll refine this.
  // Consider using a Bayesian average for more robust scoring with few reviews.
  if (reviewCount === 0) return 0; // Or some default low score
  return averageRating * (1 + reviewCount / 100); // Example: more reviews gives a slight boost
}

// Helper Function: Availability Check (Implement this next)
// function checkAvailability(providerAvailabilityData, desiredDateTime) {
//     // This will be complex depending on your availability structure.
//     // Parse desiredDateTime, check against provider's schedule (providerAvailabilityData).
//     // Return true if available, false otherwise.
//     return true; // Placeholder
// }
