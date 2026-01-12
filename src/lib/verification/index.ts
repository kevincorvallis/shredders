/**
 * Phase 1: Data Source Verification System
 *
 * Export all verification modules and utilities
 */

// Main agent
export { VerificationAgent, runVerification, verifyMountain, verifyOnlyScrapers, verifyOnlyAPIs, verifyOnlyWebcams } from './VerificationAgent';

// Individual verifiers
export { verifyScraper, verifyAllScrapers } from './scraperVerifier';
export { verifyNOAAEndpoint, verifyAllNOAA } from './noaaVerifier';
export { verifySNOTEL, verifyAllSNOTEL } from './snotelVerifier';
export { verifyOpenMeteo, verifyAllOpenMeteo } from './openMeteoVerifier';
export { verifyWebcam, verifyAllWebcams } from './webcamVerifier';

// Report generation
export { generateReport, generateMarkdownReport, saveReportToFile, printReportSummary } from './reportGenerator';

// Types
export * from './types';
