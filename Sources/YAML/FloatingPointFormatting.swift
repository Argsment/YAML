//
//  FpToString.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

func fpToString(_ v: Float, precision: Int = 0) -> String {
    if precision == 0 {
        // Shortest unique representation
        return "\(v)"
    }
    return String(format: "%.\(precision)g", v)
}

func fpToString(_ v: Double, precision: Int = 0) -> String {
    if precision == 0 {
        // Shortest unique representation
        return "\(v)"
    }
    return String(format: "%.\(precision)g", v)
}
