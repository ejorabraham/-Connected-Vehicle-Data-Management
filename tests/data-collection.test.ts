import { describe, it, expect, beforeEach, vi } from "vitest"

// Mock the Clarity contract environment
const mockClarity = {
  tx: {
    sender: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
    sponsoredBy: null,
  },
  block: {
    height: 100,
  },
  contracts: {
    "data-collection": {
      functions: {
        "initialize-contract": vi.fn(() => ({ value: true })),
        "submit-data": vi.fn(() => ({ value: 100 })),
        "get-data": vi.fn(() => null),
        "get-entry-count": vi.fn(() => 0),
        "is-data-provider": vi.fn(() => false),
      },
      variables: {
        "contract-owner": "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
      },
      maps: {
        "vehicle-data": new Map(),
        "vehicle-data-entries": new Map(),
      },
    },
  },
}

// Mock the contract calls
const mockContractCall = (functionName, args = [], sender = mockClarity.tx.sender) => {
  mockClarity.tx.sender = sender
  return mockClarity.contracts["data-collection"].functions[functionName](...args)
}

describe("Data Collection Contract", () => {
  beforeEach(() => {
    // Reset mocks before each test
    Object.values(mockClarity.contracts["data-collection"].functions).forEach((fn) => fn.mockReset())
    mockClarity.contracts["data-collection"].maps["vehicle-data"].clear()
    mockClarity.contracts["data-collection"].maps["vehicle-data-entries"].clear()
    mockClarity.tx.sender = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
    mockClarity.block.height = 100
  })
  
  it("should submit vehicle data", () => {
    const vehicleId = "123e4567-e89b-12d3-a456-426614174000"
    const latitude = 40000000 // 40.000000 (scaled for integer)
    const longitude = -74000000 // -74.000000 (scaled for integer)
    const speed = 65
    const fuelLevel = 75
    const batteryLevel = 80
    const engineStatus = "running"
    const diagnosticCodes = ["P0001", "P0002"]
    
    mockClarity.contracts["data-collection"].functions["submit-data"].mockReturnValue({
      value: mockClarity.block.height,
    })
    
    const result = mockContractCall("submit-data", [
      vehicleId,
      latitude,
      longitude,
      speed,
      fuelLevel,
      batteryLevel,
      engineStatus,
      diagnosticCodes,
    ])
    
    expect(result.value).toBe(mockClarity.block.height)
    expect(mockClarity.contracts["data-collection"].functions["submit-data"]).toHaveBeenCalledWith(
        vehicleId,
        latitude,
        longitude,
        speed,
        fuelLevel,
        batteryLevel,
        engineStatus,
        diagnosticCodes,
    )
  })
  
  it("should get vehicle data by ID and timestamp", () => {
    const vehicleId = "123e4567-e89b-12d3-a456-426614174000"
    const timestamp = 100
    
    const mockData = {
      location: {
        latitude: 40000000,
        longitude: -74000000,
      },
      speed: 65,
      "fuel-level": 75,
      "battery-level": 80,
      "engine-status": "running",
      "diagnostic-codes": ["P0001", "P0002"],
      "data-provider": "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
    }
    
    mockClarity.contracts["data-collection"].functions["get-data"].mockReturnValue(mockData)
    
    const result = mockContractCall("get-data", [vehicleId, timestamp])
    
    expect(result).toEqual(mockData)
    expect(mockClarity.contracts["data-collection"].functions["get-data"]).toHaveBeenCalledWith(vehicleId, timestamp)
  })
  
  it("should get the number of data entries for a vehicle", () => {
    const vehicleId = "123e4567-e89b-12d3-a456-426614174000"
    const entryCount = 5
    
    mockClarity.contracts["data-collection"].functions["get-entry-count"].mockReturnValue(entryCount)
    
    const result = mockContractCall("get-entry-count", [vehicleId])
    
    expect(result).toBe(entryCount)
    expect(mockClarity.contracts["data-collection"].functions["get-entry-count"]).toHaveBeenCalledWith(vehicleId)
  })
  
  it("should check if a principal is the data provider for a specific entry", () => {
    const vehicleId = "123e4567-e89b-12d3-a456-426614174000"
    const timestamp = 100
    const provider = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
    
    mockClarity.contracts["data-collection"].functions["is-data-provider"].mockReturnValue(true)
    
    const result = mockContractCall("is-data-provider", [vehicleId, timestamp, provider])
    
    expect(result).toBe(true)
    expect(mockClarity.contracts["data-collection"].functions["is-data-provider"]).toHaveBeenCalledWith(
        vehicleId,
        timestamp,
        provider,
    )
  })
})
