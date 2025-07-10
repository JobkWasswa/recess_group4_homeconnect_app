// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const dayjs = require("dayjs");
const utc = require("dayjs/plugin/utc");
const timezone = require("dayjs/plugin/timezone");
const isBetween = require("dayjs/plugin/isBetween"); // Add this plugin for range checks
dayjs.extend(utc);
dayjs.extend(timezone);
dayjs.extend(isBetween); // Extend dayjs with isBetween

admin.initializeApp(); // Initialize Firebase Admin SDK

exports.getRecommendedProviders = functions.https.onCall(
  async (requestData, context) => {
    // Authenticate the user (optional, but good practice for any function needing user context)
    // if (!context.auth) {
    //     throw new functions.https.HttpsError(
    //         'unauthenticated',
    //         'The function must be called while authenticated.'
    //     );
    // }

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
    console.log(
      "CF received desiredDateTime:",
      requestData.data?.desiredDateTime
    );

    const {
      serviceCategory,
      homeownerLatitude,
      homeownerLongitude,
      desiredDateTime, // This will now be used for availability filtering
    } = requestData.data;

    // Convert desiredDateTime to a Day.js object if provided
    let parsedDesiredDateTime = null;
    if (desiredDateTime) {
      try {
        // Assume desiredDateTime is an ISO 8601 string, parse it as UTC
        parsedDesiredDateTime = dayjs.utc(desiredDateTime);
        if (!parsedDesiredDateTime.isValid()) {
          throw new Error("Invalid desiredDateTime format");
        }
        // Ensure the desired time is not in the past relative to function execution time
        // We use a small buffer (e.g., 5 minutes) to account for network latency/clock differences
        if (
          parsedDesiredDateTime.isBefore(dayjs.utc().subtract(5, "minutes"))
        ) {
          throw new functions.https.HttpsError(
            "invalid-argument",
            "Desired date and time cannot be in the past."
          );
        }
      } catch (e) {
        console.error(
          "Invalid desiredDateTime received:",
          desiredDateTime,
          e.message
        );
        throw new functions.https.HttpsError(
          "invalid-argument",
          `Invalid desiredDateTime format: ${e.message}`
        );
      }
    }

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
        error.message
      );
    }

    const eligibleProviders = [];

    for (const doc of providersSnapshot.docs) {
      const providerData = doc.data();
      const providerId = doc.id;
      console.log(`Processing provider: ${providerId}`);

      let meetsAllCriteria = true;

      // --- Geospatial Filtering ---
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

      // --- AVAILABILITY FILTERING based on desiredDateTime and provider's default working hours ---
      // Only perform this check if a specific desiredDateTime was provided by the user.
      if (meetsAllCriteria && parsedDesiredDateTime) {
        const isProviderAvailable = checkProviderAvailability(
          providerData,
          parsedDesiredDateTime
        );

        if (!isProviderAvailable) {
          console.log(
            `Provider ${providerId} not available at ${parsedDesiredDateTime.toISOString()} based on their schedule/blocked dates. Skipping.`
          );
          meetsAllCriteria = false;
        }
      }
      // --- END AVAILABILITY FILTERING ---

      if (meetsAllCriteria) {
        const rating = providerData.averageRating ?? 0;
        const reviewCount = providerData.numberOfReviews ?? 0;
        const score = calculateRatingScore(rating, reviewCount, distance);

        eligibleProviders.push({
          id: providerId,
          name: providerData.name ?? "Unnamed Provider",
          profilePhoto: providerData.profilePhoto ?? null,
          categories: providerData.categories ?? [],
          // availableToday is no longer directly pulled from Firestore for real-time availability
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

// Helper Function: Distance Calculation (Haversine) - UNCHANGED
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

// Helper Function: Rating Score - UNCHANGED
function calculateRatingScore(averageRating, reviewCount, distanceKm) {
  if (reviewCount === 0) return 0;

  let score = averageRating;
  score += Math.min(reviewCount * 0.05, 1.0);

  if (distanceKm !== null && distanceKm !== undefined) {
    score -= Math.min(distanceKm * 0.1, 2.0);
  }

  return Math.max(0, score);
}

// --- REVISED HELPER FUNCTION: checkProviderAvailability ---
/**
 * Checks if a provider is generally available at a specific desired date and time
 * based on their default working hours and blocked dates.
 * This function does NOT check for existing bookings. That will be part of the booking creation logic.
 *
 * @param {object} providerData - The full provider document data from Firestore.
 * @param {dayjs.Dayjs} desiredDateTime - A Day.js object representing the desired booking time (in UTC).
 * @returns {boolean} True if the provider is generally available (not blocked and within working hours), false otherwise.
 */
function checkProviderAvailability(providerData, desiredDateTime) {
  // 1. Check for 'available' top-level boolean flag (manual override)
  // If you have a simple boolean field for providers to mark themselves completely unavailable
  // beyond their schedule, you would check it here. For now, assuming you might not.
  // if (providerData.isGloballyUnavailable === true) {
  //     console.log(`Provider is globally unavailable.`);
  //     return false;
  // }

  // 1. Check for blocked dates (full day unavailability)
  const desiredDateString = desiredDateTime.format("YYYY-MM-DD"); // e.g., "2025-07-10"
  if (
    providerData.blockedDates &&
    providerData.blockedDates.includes(desiredDateString)
  ) {
    console.log(`Provider is blocked on ${desiredDateString}`);
    return false;
  }

  // 2. Check general weekly working hours
  const dayOfWeek = desiredDateTime.format("dddd"); // e.g., "Thursday"
  const desiredTimeHourMin = desiredDateTime.format("HH:mm"); // e.g., "15:34"

  // Ensure defaultWorkingHours exists and has entries for the day of the week
  const workingHoursRanges = providerData.defaultWorkingHours?.[dayOfWeek];

  if (!workingHoursRanges || workingHoursRanges.length === 0) {
    console.log(`Provider has no default working hours on ${dayOfWeek}`);
    return false; // Not working on this day
  }

  let isWithinWorkingHours = false;
  for (const range of workingHoursRanges) {
    // Example range: "09:00-12:00"
    const [startTimeStr, endTimeStr] = range.split("-");

    // Create Day.js objects for the start and end of the working range for *that specific desired date*.
    // We use desiredDateString to ensure the date context is correct for the time comparison.
    // Append 'Z' to treat as UTC, matching how desiredDateTime is parsed.
    const rangeStart = dayjs.utc(`${desiredDateString}T${startTimeStr}:00Z`);
    const rangeEnd = dayjs.utc(`${desiredDateString}T${endTimeStr}:00Z`);

    // Check if the desired booking time is within this specific working range
    // '[)' means inclusive of start, exclusive of end. This is common for time slots.
    // So, 09:00 is available, but 12:00 (the end time) is not.
    if (desiredDateTime.isBetween(rangeStart, rangeEnd, null, "[)")) {
      isWithinWorkingHours = true;
      break;
    }
  }

  if (!isWithinWorkingHours) {
    console.log(
      `Desired time ${desiredTimeHourMin} not within default working hours on ${dayOfWeek}`
    );
    return false;
  }

  // If it passed all checks, the provider is generally available at that time
  return true;
}
