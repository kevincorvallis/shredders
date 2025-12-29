import Foundation

// MARK: - Extended Mock Data for All Mountains
extension Mountain {
    static let allMountainsMock: [Mountain] = [
        // Washington - Cascades
        Mountain(
            id: "baker",
            name: "Mt. Baker",
            shortName: "Baker",
            location: MountainLocation(lat: 48.857, lng: -121.669),
            elevation: MountainElevation(base: 3500, summit: 5089),
            region: "washington",
            color: "#3b82f6",
            website: "https://www.mtbaker.us",
            hasSnotel: true,
            webcamCount: 1,
            logo: "/logos/baker.svg",
            status: MountainStatus(
                isOpen: true,
                percentOpen: 85,
                liftsOpen: "8/10",
                runsOpen: "70/82",
                message: "Great conditions!",
                lastUpdated: nil
            )
        ),
        Mountain(
            id: "stevens",
            name: "Stevens Pass",
            shortName: "Stevens",
            location: MountainLocation(lat: 47.745, lng: -121.089),
            elevation: MountainElevation(base: 4061, summit: 5845),
            region: "washington",
            color: "#10b981",
            website: "https://www.stevenspass.com",
            hasSnotel: true,
            webcamCount: 1,
            logo: "/logos/stevens.svg",
            status: MountainStatus(
                isOpen: true,
                percentOpen: 90,
                liftsOpen: "9/10",
                runsOpen: "55/61",
                message: "Full operations",
                lastUpdated: nil
            )
        ),
        Mountain(
            id: "crystal",
            name: "Crystal Mountain",
            shortName: "Crystal",
            location: MountainLocation(lat: 46.935, lng: -121.474),
            elevation: MountainElevation(base: 4400, summit: 7012),
            region: "washington",
            color: "#8b5cf6",
            website: "https://www.crystalmountainresort.com",
            hasSnotel: true,
            webcamCount: 0,
            logo: "/logos/crystal.svg",
            status: MountainStatus(
                isOpen: true,
                percentOpen: 88,
                liftsOpen: "10/11",
                runsOpen: "50/57",
                message: "Excellent skiing",
                lastUpdated: nil
            )
        ),
        Mountain(
            id: "snoqualmie",
            name: "Summit at Snoqualmie",
            shortName: "Snoqualmie",
            location: MountainLocation(lat: 47.428, lng: -121.413),
            elevation: MountainElevation(base: 3000, summit: 5400),
            region: "washington",
            color: "#f59e0b",
            website: "https://www.summitatsnoqualmie.com",
            hasSnotel: true,
            webcamCount: 0,
            logo: "/logos/snoqualmie.svg",
            status: MountainStatus(
                isOpen: true,
                percentOpen: 95,
                liftsOpen: "20/22",
                runsOpen: "64/67",
                message: "All areas open",
                lastUpdated: nil
            )
        ),
        Mountain(
            id: "whitepass",
            name: "White Pass",
            shortName: "White Pass",
            location: MountainLocation(lat: 46.637, lng: -121.391),
            elevation: MountainElevation(base: 4500, summit: 6500),
            region: "washington",
            color: "#ec4899",
            website: "https://skiwhitepass.com",
            hasSnotel: true,
            webcamCount: 0,
            logo: "/logos/whitepass.svg",
            status: MountainStatus(
                isOpen: true,
                percentOpen: 75,
                liftsOpen: "4/6",
                runsOpen: "30/40",
                message: "Good conditions",
                lastUpdated: nil
            )
        ),

        // Oregon
        Mountain(
            id: "meadows",
            name: "Mt. Hood Meadows",
            shortName: "Meadows",
            location: MountainLocation(lat: 45.331, lng: -121.665),
            elevation: MountainElevation(base: 4523, summit: 7300),
            region: "oregon",
            color: "#06b6d4",
            website: "https://www.skihood.com",
            hasSnotel: true,
            webcamCount: 0,
            logo: "/logos/meadows.svg",
            status: MountainStatus(
                isOpen: true,
                percentOpen: 80,
                liftsOpen: "7/9",
                runsOpen: "65/81",
                message: "Great skiing",
                lastUpdated: nil
            )
        ),
        Mountain(
            id: "timberline",
            name: "Timberline Lodge",
            shortName: "Timberline",
            location: MountainLocation(lat: 45.331, lng: -121.711),
            elevation: MountainElevation(base: 4540, summit: 8540),
            region: "oregon",
            color: "#14b8a6",
            website: "https://www.timberlinelodge.com",
            hasSnotel: true,
            webcamCount: 0,
            logo: "/logos/timberline.svg",
            status: MountainStatus(
                isOpen: true,
                percentOpen: 70,
                liftsOpen: "4/6",
                runsOpen: "40/57",
                message: "Spring skiing",
                lastUpdated: nil
            )
        ),
        Mountain(
            id: "bachelor",
            name: "Mt. Bachelor",
            shortName: "Bachelor",
            location: MountainLocation(lat: 43.979, lng: -121.688),
            elevation: MountainElevation(base: 5700, summit: 9065),
            region: "oregon",
            color: "#f97316",
            website: "https://www.mtbachelor.com",
            hasSnotel: true,
            webcamCount: 0,
            logo: "/logos/bachelor.svg",
            status: MountainStatus(
                isOpen: true,
                percentOpen: 85,
                liftsOpen: "10/12",
                runsOpen: "62/73",
                message: "Excellent conditions",
                lastUpdated: nil
            )
        ),
        Mountain(
            id: "ashland",
            name: "Mt. Ashland",
            shortName: "Ashland",
            location: MountainLocation(lat: 42.086, lng: -122.715),
            elevation: MountainElevation(base: 6350, summit: 7533),
            region: "oregon",
            color: "#ea580c",
            website: "https://www.mtashland.com",
            hasSnotel: true,
            webcamCount: 0,
            logo: "/logos/ashland.svg",
            status: MountainStatus(
                isOpen: false,
                percentOpen: 0,
                liftsOpen: "0/4",
                runsOpen: "0/23",
                message: "Closed for season",
                lastUpdated: nil
            )
        ),
        Mountain(
            id: "willamette",
            name: "Willamette Pass",
            shortName: "Willamette",
            location: MountainLocation(lat: 43.596, lng: -122.039),
            elevation: MountainElevation(base: 5128, summit: 6683),
            region: "oregon",
            color: "#84cc16",
            website: "https://www.willamettepass.com",
            hasSnotel: true,
            webcamCount: 0,
            logo: "/logos/willamette.svg",
            status: MountainStatus(
                isOpen: true,
                percentOpen: 60,
                liftsOpen: "2/4",
                runsOpen: "18/30",
                message: "Limited operations",
                lastUpdated: nil
            )
        ),
        Mountain(
            id: "hoodoo",
            name: "Hoodoo Ski Area",
            shortName: "Hoodoo",
            location: MountainLocation(lat: 44.408, lng: -121.870),
            elevation: MountainElevation(base: 4668, summit: 5703),
            region: "oregon",
            color: "#f472b6",
            website: "https://www.skihoodoo.com",
            hasSnotel: true,
            webcamCount: 0,
            logo: "/logos/hoodoo.svg",
            status: MountainStatus(
                isOpen: true,
                percentOpen: 70,
                liftsOpen: "3/5",
                runsOpen: "22/32",
                message: "Good conditions",
                lastUpdated: nil
            )
        ),

        // Washington - Eastern
        Mountain(
            id: "missionridge",
            name: "Mission Ridge",
            shortName: "Mission Ridge",
            location: MountainLocation(lat: 47.293, lng: -120.398),
            elevation: MountainElevation(base: 4570, summit: 6820),
            region: "washington",
            color: "#dc2626",
            website: "https://www.missionridge.com",
            hasSnotel: true,
            webcamCount: 0,
            logo: "/logos/missionridge.svg",
            status: MountainStatus(
                isOpen: true,
                percentOpen: 80,
                liftsOpen: "4/5",
                runsOpen: "32/40",
                message: "Good coverage",
                lastUpdated: nil
            )
        ),
        Mountain(
            id: "fortynine",
            name: "49 Degrees North",
            shortName: "49°N",
            location: MountainLocation(lat: 48.795, lng: -117.565),
            elevation: MountainElevation(base: 3923, summit: 5774),
            region: "washington",
            color: "#7c3aed",
            website: "https://www.ski49n.com",
            hasSnotel: true,
            webcamCount: 0,
            logo: "/logos/fortynine.svg",
            status: MountainStatus(
                isOpen: true,
                percentOpen: 75,
                liftsOpen: "5/7",
                runsOpen: "28/38",
                message: "Good skiing",
                lastUpdated: nil
            )
        ),

        // Idaho
        Mountain(
            id: "schweitzer",
            name: "Schweitzer Mountain",
            shortName: "Schweitzer",
            location: MountainLocation(lat: 48.368, lng: -116.622),
            elevation: MountainElevation(base: 4000, summit: 6400),
            region: "idaho",
            color: "#0ea5e9",
            website: "https://www.schweitzer.com",
            hasSnotel: true,
            webcamCount: 0,
            logo: "/logos/schweitzer.svg",
            status: MountainStatus(
                isOpen: true,
                percentOpen: 85,
                liftsOpen: "8/10",
                runsOpen: "70/82",
                message: "Great conditions",
                lastUpdated: nil
            )
        ),
        Mountain(
            id: "lookout",
            name: "Lookout Pass",
            shortName: "Lookout",
            location: MountainLocation(lat: 47.454, lng: -115.713),
            elevation: MountainElevation(base: 4150, summit: 5650),
            region: "idaho",
            color: "#059669",
            website: "https://www.skilookout.com",
            hasSnotel: true,
            webcamCount: 0,
            logo: "/logos/lookout.svg",
            status: MountainStatus(
                isOpen: true,
                percentOpen: 65,
                liftsOpen: "3/4",
                runsOpen: "26/40",
                message: "Limited terrain",
                lastUpdated: nil
            )
        ),
    ]
}
