/**
 * Temperature Lapse Rate Calculations
 *
 * Calculates temperature at different elevations using atmospheric lapse rate.
 * The lapse rate is the rate at which temperature decreases with altitude.
 *
 * Standard atmospheric lapse rate: ~3.5°F per 1000 feet
 * (This is a moderate value suitable for mountain weather conditions)
 */

/**
 * Standard atmospheric lapse rate in °F per 1000 feet
 *
 * Notes:
 * - Dry adiabatic lapse rate: 5.5°F/1000ft
 * - Saturated adiabatic lapse rate: 3.0-3.3°F/1000ft
 * - We use 3.5°F/1000ft as a reasonable middle ground for ski resorts
 */
const LAPSE_RATE_PER_1000FT = 3.5;

export interface ElevationTemperatures {
  base: number;
  mid: number;
  summit: number;
  referenceElevation: number; // The elevation where the reference temp was measured
  referenceTemp: number; // The measured temperature
  lapseRate: number; // The lapse rate used (°F per 1000 ft)
}

/**
 * Calculate temperature at a specific elevation given a reference temperature
 *
 * @param referenceTemp - Temperature at the reference elevation (°F)
 * @param referenceElevation - Elevation where temperature was measured (feet)
 * @param targetElevation - Elevation to calculate temperature for (feet)
 * @param lapseRate - Optional custom lapse rate (°F per 1000 ft), defaults to 3.5
 * @returns Temperature at target elevation (°F)
 */
export function calculateTemperatureAtElevation(
  referenceTemp: number,
  referenceElevation: number,
  targetElevation: number,
  lapseRate: number = LAPSE_RATE_PER_1000FT
): number {
  const elevationDifference = targetElevation - referenceElevation;
  const temperatureChange = -(elevationDifference / 1000) * lapseRate;

  return Math.round(referenceTemp + temperatureChange);
}

/**
 * Calculate temperatures at base, mid, and summit elevations
 *
 * @param referenceTemp - Measured temperature (°F)
 * @param referenceElevation - Elevation where temp was measured (feet)
 * @param baseElevation - Mountain base elevation (feet)
 * @param summitElevation - Mountain summit elevation (feet)
 * @param lapseRate - Optional custom lapse rate (°F per 1000 ft)
 * @returns Object with base, mid, and summit temperatures
 */
export function calculateMountainTemperatures(
  referenceTemp: number,
  referenceElevation: number,
  baseElevation: number,
  summitElevation: number,
  lapseRate: number = LAPSE_RATE_PER_1000FT
): ElevationTemperatures {
  const midElevation = Math.round((baseElevation + summitElevation) / 2);

  return {
    base: calculateTemperatureAtElevation(referenceTemp, referenceElevation, baseElevation, lapseRate),
    mid: calculateTemperatureAtElevation(referenceTemp, referenceElevation, midElevation, lapseRate),
    summit: calculateTemperatureAtElevation(referenceTemp, referenceElevation, summitElevation, lapseRate),
    referenceElevation,
    referenceTemp,
    lapseRate,
  };
}

/**
 * Estimate the reference elevation for temperature measurement
 *
 * For SNOTEL stations, we know the exact elevation.
 * For NOAA grid points, we estimate based on mountain location.
 *
 * @param snotelElevation - SNOTEL station elevation if available
 * @param baseElevation - Mountain base elevation
 * @param summitElevation - Mountain summit elevation
 * @returns Estimated elevation where temperature was measured
 */
export function estimateReferenceElevation(
  snotelElevation: number | null,
  baseElevation: number,
  summitElevation: number
): number {
  // If we have SNOTEL, use its elevation
  if (snotelElevation !== null) {
    return snotelElevation;
  }

  // Otherwise, assume temperature is measured at mid-mountain
  // (NOAA grid points typically represent valley/mid-elevation locations)
  return Math.round((baseElevation + summitElevation) / 2);
}
