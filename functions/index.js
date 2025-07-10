// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp(); // Initialize Firebase Admin SDK

exports.getRecommendedProviders = functions.https.onCall(
  async (requestData, context) => {
    console.log("CF received raw requestData:", requestData);
    console.log(
      "CF received serviceCategory:",
      requestData.data?.serviceCategory
    );
    console.log(
      "CF received homeownerLatitude:",
      requestData.data?.homeownerLatitude
    );
    console.log(
      "CF received homeownerLongitude:",
      requestData.data?.homeownerLongitude
    );

    const {
      serviceCategory,
      homeownerLatitude,
      homeownerLongitude,
      desiredDateTime,
    } = requestData.data;

    if (
      !serviceCategory ||
      typeof serviceCategory !== "string" ||
      typeof homeownerLatitude !== "number" ||
      !Number.isFinite(homeownerLatitude) ||
      typeof homeownerLongitude !== "number" ||
      !Number.isFinite(homeownerLongitude)
    ) {
      console.error("Validation failed for incoming data:", {
        serviceCategory,
        homeownerLatitude,
        homeownerLongitude,
      });

      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing or invalid required parameters (serviceCategory, homeownerLatitude, homeownerLongitude)."
      );
    }

    const homeownerLocation = {
      latitude: homeownerLatitude,
      longitude: homeownerLongitude,
    };
    const MAX_DISTANCE_KM = 7;

    console.log(
      `Searching for '${serviceCategory}' providers near (${homeownerLatitude}, ${homeownerLongitude})`
    );

    let providersSnapshot;
    try {
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
        error
      );
    }

    const eligibleProviders = [];

    for (const doc of providersSnapshot.docs) {
      const providerData = doc.data();
      const providerId = doc.id;
      console.log(`Processing provider: ${providerId}`);

      let meetsAllCriteria = true;

      let distance = null;
      if (
        !providerData.location ||
        typeof providerData.location.latitude === "undefined" ||
        typeof providerData.location.longitude === "undefined"
      ) {
        console.warn(`Provider ${providerId} missing location. Skipping.`);
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
        );

        if (distance > MAX_DISTANCE_KM) {
          console.log(
            `Provider ${providerId} too far (${distance.toFixed(
              2
            )} km). Skipping.`
          );
          meetsAllCriteria = false;
        }
      }

      if (meetsAllCriteria) {
        const providerAvailableToday = providerData.availableToday ?? true;

        if (desiredDateTime) {
          if (!providerAvailableToday) {
            console.log(
              `Provider ${providerId} not available on specified date. Skipping.`
            );
            meetsAllCriteria = false;
          }
        } else {
          if (!providerAvailableToday) {
            console.log(
              `Provider ${providerId} not generally available today. Skipping.`
            );
            meetsAllCriteria = false;
          }
        }
      }

      if (meetsAllCriteria) {
        const rating = providerData.averageRating ?? 0;
        const reviewCount = providerData.numberOfReviews ?? 0;
        const score = calculateRatingScore(rating, reviewCount, distance);

        eligibleProviders.push({
          id: providerId,
          name: providerData.name ?? "Unnamed Provider",
          profilePhoto: providerData.profilePhoto ?? null,
          categories: providerData.categories ?? [],
          availableToday: providerData.availableToday ?? false,
          service: serviceCategory,
          rating: rating,
          reviewCount: reviewCount,
          distanceKm:
            distance !== null ? parseFloat(distance.toFixed(2)) : null,
          score: score,
        });
      }
    }

    eligibleProviders.sort((a, b) => b.score - a.score);

    console.log(`Found ${eligibleProviders.length} eligible providers.`);
    return { providers: eligibleProviders };
  }
);

// Helper Function: Distance Calculation (Haversine)
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Helper Function: Rating Score
function calculateRatingScore(averageRating, reviewCount, distanceKm) {
  if (reviewCount === 0) return 0;

  let score = averageRating;
  score += Math.min(reviewCount * 0.05, 1.0);

  if (distanceKm !== null && distanceKm !== undefined) {
    score -= Math.min(distanceKm * 0.1, 2.0);
  }

  return Math.max(0, score);
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
