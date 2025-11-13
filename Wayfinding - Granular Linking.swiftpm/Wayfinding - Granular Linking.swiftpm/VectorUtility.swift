import SwiftUI

import CoreML
//
//  VectorUtility.swift
//  
//
//  Created by Anonymous on 7/31/25.
//
import Foundation

enum CosineType {
    case Similarity
    case Distance
}

public class VectorUtility {
    
    // courtesy of nlp-sentence-embedding vector tools on GitHub.
    
    // https://stackoverflow.com/questions/58381092/difference-between-cosine-similarity-and-cosine-distance
    // https://www.datacamp.com/tutorial/cosine-distance (better explanation)
    private static func dot(_ a: [Float], _ b: [Float]) -> Float {
        assert(a.count == b.count, "Vectors must have the same dimension")
        let result = zip(a, b)
            .map { $0 * $1 }
            .reduce(0, +)
        
        return result
    }
    
    /// Magnitude
    private static func mag(_ vector: [Float]) -> Float {
        // Magnitude of the vector is the square root of the dot product of the vector with itself.
        return sqrt(dot(vector, vector))
    }
    
    /// Returns the similarity between two vectors
    ///
    /// - Parameters:
    ///     - a: The first vector
    ///     - b: The second vector
    public static func cosineSimilarity(a: [Float], b: [Float]) -> Float {
        return self.dot(a, b) / (self.mag(a) * self.mag(b))
    }
    
    /// Returns the difference between two vectors. Cosine distance is defined as `1 - cosineSimilarity(a, b)`
    ///
    /// - Parameters:
    ///     - a: The first vector
    ///     - b: The second vector
    public static func cosineDifference(a: [Float], b: [Float]) -> Float {
        return 1 - self.cosineSimilarity(a: a, b: b)
    }
    
    
    public static func getArray(forMDarray ma: MLMultiArray) -> [Float] {
        let pointer = UnsafeMutablePointer<Float>(OpaquePointer(ma.dataPointer))
        let buffer = UnsafeBufferPointer(start: pointer, count: ma.count)
        return Array(buffer)
    }
    
    
}
