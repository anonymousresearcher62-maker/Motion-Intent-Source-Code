import SwiftUI
import CoreML
import ZIPFoundation

/// Model Prediction Input Type
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
public class TinyVitInput : MLFeatureProvider {
    
    /// input_1 as color (kCVPixelFormatType_32BGRA) image buffer, 224 pixels wide by 224 pixels high
    public var input_1: CVPixelBuffer
    
    public var featureNames: Set<String> { ["input_1"] }
    
    public func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "input_1" {
            return MLFeatureValue(pixelBuffer: input_1)
        }
        return nil
    }
    
    public init(input_1: CVPixelBuffer) {
        self.input_1 = input_1
    }
    
    convenience init(input_1With input_1: CGImage) throws {
        self.init(input_1: try MLFeatureValue(cgImage: input_1, pixelsWide: 224, pixelsHigh: 224, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!)
    }
    
    convenience init(input_1At input_1: URL) throws {
        self.init(input_1: try MLFeatureValue(imageAt: input_1, pixelsWide: 224, pixelsHigh: 224, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!)
    }
    
    func setInput_1(with input_1: CGImage) throws  {
        self.input_1 = try MLFeatureValue(cgImage: input_1, pixelsWide: 224, pixelsHigh: 224, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!
    }
    
    func setInput_1(with input_1: URL) throws  {
        self.input_1 = try MLFeatureValue(imageAt: input_1, pixelsWide: 224, pixelsHigh: 224, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!
    }
    
}


/// Model Prediction Output Type
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
public class TinyVitOutput : MLFeatureProvider {
    
    /// Source provided by CoreML
    public let provider : MLFeatureProvider
    
    /// output as 320 element vector of floats
    public var output: MLMultiArray {
        provider.featureValue(for: "output")!.multiArrayValue!
    }
    
    /// output as 320 element vector of floats
    public var outputShapedArray: MLShapedArray<Float> {
        MLShapedArray<Float>(output)
    }
    
    public var featureNames: Set<String> {
        provider.featureNames
    }
    
    public func featureValue(for featureName: String) -> MLFeatureValue? {
        provider.featureValue(for: featureName)
    }
    
    public init(output: MLMultiArray) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["output" : MLFeatureValue(multiArray: output)])
    }
    
    public init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
public class TinyVit {
    public let model: MLModel
    
    /// URL of model assuming it was installed in the same bundle as this class
    public class var urlOfModelInThisBundle : URL {
        
        // this is a patch to get this working on ios app playgrounds
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelURL = docs.appendingPathComponent("TinyVit.mlmodelc")
        print(modelURL)
        return modelURL
    }
    
    /**
     Construct TinyVit instance with an existing MLModel object.
     
     Usually the application does not use this initializer unless it makes a subclass of TinyVit.
     Such application may want to use `MLModel(contentsOfURL:configuration:)` and `TinyVit.urlOfModelInThisBundle` to create a MLModel object to pass-in.
     
     - parameters:
     - model: MLModel object
     */
    public init(model: MLModel) {
        self.model = model
    }
    
    /**
     Construct a model with configuration
     
     - parameters:
     - configuration: the desired model configuration
     
     - throws: an NSError object that describes the problem
     */
    public convenience init(configuration: MLModelConfiguration = MLModelConfiguration()) throws {
        try self.init(contentsOf: type(of:self).urlOfModelInThisBundle, configuration: configuration)
    }
    
    /**
     Construct TinyVit instance with explicit path to mlmodelc file
     - parameters:
     - modelURL: the file url of the model
     
     - throws: an NSError object that describes the problem
     */
    convenience init(contentsOf modelURL: URL) throws {
        try self.init(model: MLModel(contentsOf: modelURL))
    }
    
    /**
     Construct a model with URL of the .mlmodelc directory and configuration
     
     - parameters:
     - modelURL: the file url of the model
     - configuration: the desired model configuration
     
     - throws: an NSError object that describes the problem
     */
    convenience init(contentsOf modelURL: URL, configuration: MLModelConfiguration) throws {
        try self.init(model: MLModel(contentsOf: modelURL, configuration: configuration))
    }
    
    /**
     Construct TinyVit instance asynchronously with optional configuration.
     
     Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.
     
     - parameters:
     - configuration: the desired model configuration
     - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
     */
    class func load(configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<TinyVit, Error>) -> Void) {
        load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration, completionHandler: handler)
    }
    
    /**
     Construct TinyVit instance asynchronously with optional configuration.
     
     Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.
     
     - parameters:
     - configuration: the desired model configuration
     */
    class func load(configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> TinyVit {
        try await load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration)
    }
    
    /**
     Construct TinyVit instance asynchronously with URL of the .mlmodelc directory with optional configuration.
     
     Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.
     
     - parameters:
     - modelURL: the URL to the model
     - configuration: the desired model configuration
     - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
     */
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<TinyVit, Error>) -> Void) {
        MLModel.load(contentsOf: modelURL, configuration: configuration) { result in
            switch result {
            case .failure(let error):
                handler(.failure(error))
            case .success(let model):
                handler(.success(TinyVit(model: model)))
            }
        }
    }
    
    /**
     Construct TinyVit instance asynchronously with URL of the .mlmodelc directory with optional configuration.
     
     Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.
     
     - parameters:
     - modelURL: the URL to the model
     - configuration: the desired model configuration
     */
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> TinyVit {
        let model = try await MLModel.load(contentsOf: modelURL, configuration: configuration)
        return TinyVit(model: model)
    }
    
    /**
     Make a prediction using the structured interface
     
     It uses the default function if the model has multiple functions.
     
     - parameters:
     - input: the input to the prediction as TinyVitInput
     
     - throws: an NSError object that describes the problem
     
     - returns: the result of the prediction as TinyVitOutput
     */
    public func prediction(input: TinyVitInput) throws -> TinyVitOutput {
        try prediction(input: input, options: MLPredictionOptions())
    }
    
    /**
     Make a prediction using the structured interface
     
     It uses the default function if the model has multiple functions.
     
     - parameters:
     - input: the input to the prediction as TinyVitInput
     - options: prediction options
     
     - throws: an NSError object that describes the problem
     
     - returns: the result of the prediction as TinyVitOutput
     */
    public func prediction(input: TinyVitInput, options: MLPredictionOptions) throws -> TinyVitOutput {
        let outFeatures = try model.prediction(from: input, options: options)
        return TinyVitOutput(features: outFeatures)
    }
    
    /**
     Make an asynchronous prediction using the structured interface
     
     It uses the default function if the model has multiple functions.
     
     - parameters:
     - input: the input to the prediction as TinyVitInput
     - options: prediction options
     
     - throws: an NSError object that describes the problem
     
     - returns: the result of the prediction as TinyVitOutput
     */
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    public func prediction(input: TinyVitInput, options: MLPredictionOptions = MLPredictionOptions()) async throws -> TinyVitOutput {
        let outFeatures = try await model.prediction(from: input, options: options)
        return TinyVitOutput(features: outFeatures)
    }
    
    /**
     Make a prediction using the convenience interface
     
     It uses the default function if the model has multiple functions.
     
     - parameters:
     - input_1: color (kCVPixelFormatType_32BGRA) image buffer, 224 pixels wide by 224 pixels high
     
     - throws: an NSError object that describes the problem
     
     - returns: the result of the prediction as TinyVitOutput
     */
    public func prediction(input_1: CVPixelBuffer) throws -> TinyVitOutput {
        let input_ = TinyVitInput(input_1: input_1)
        return try prediction(input: input_)
    }
    
    /**
     Make a batch prediction using the structured interface
     
     It uses the default function if the model has multiple functions.
     
     - parameters:
     - inputs: the inputs to the prediction as [TinyVitInput]
     - options: prediction options
     
     - throws: an NSError object that describes the problem
     
     - returns: the result of the prediction as [TinyVitOutput]
     */
    public func predictions(inputs: [TinyVitInput], options: MLPredictionOptions = MLPredictionOptions()) throws -> [TinyVitOutput] {
        let batchIn = MLArrayBatchProvider(array: inputs)
        let batchOut = try model.predictions(from: batchIn, options: options)
        var results : [TinyVitOutput] = []
        results.reserveCapacity(inputs.count)
        for i in 0..<batchOut.count {
            let outProvider = batchOut.features(at: i)
            let result =  TinyVitOutput(features: outProvider)
            results.append(result)
        }
        return results
    }
}


class TinyViTWrapper: ObservableObject {
    
    @Published public var model: TinyVit? = nil
    private var tmpUrl: URL?
    
    init() {
        
        
    }
    
    public static func downloadModel(fromURL ustring: String) async {
        // Self host the file so you can download it to your app's sandbox.
        // I just put it in a folder and launched an easy http web server with python.
        // ensure that it's the correct file (mlmodelc precompiled)
        
        // Host it as a single zip file or something because otherwise it will downlaod as
        // a folder!!! (I Use ZIPFoundation as a package dependency)
        let url = URL(string: ustring)
        do {
            let (downloadUrl, _) = try await URLSession.shared.download(from: url!)
            print("Downloaded to \(downloadUrl)")
            
            
            
            // move to a more permanent directory under app sandbox.
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let targetDir = docs.appendingPathComponent("TinyVit.mlmodelc.zip")
            
            try FileManager.default.copyItem(at: downloadUrl, to: targetDir)
            
            let local = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            
            let files = FileManager()
            //try files.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            try files.unzipItem(at: targetDir, to: local)
            
            
            
            
            return
        } catch let error {
            print("Error downloading \(error)")
        }
        
        
        
    }
    
    public func loadModel() async {
        print("loading")
        do {
            self.model = try TinyVit()
        } catch let error {
            print("could not initialize ViT. \(error)")
        }
        print("successful")
    }
    
    // defaults to obtaining cosine similarity between vectors.
    // can switch to distance. Instead of ranigng -1 to 1 for cs, it'd be 0 to 2 for distance.
    public func similarityBetween(imageOne ia: UIImage, andImageTwo ib: UIImage, usingCosineType ctype: CosineType = .Similarity) -> Float {
        print("test2")
        
        let imOnePrepared = ia.prepareForModel(withHeightWidth: 224)
        let imTwoPrepared = ib.prepareForModel(withHeightWidth: 224)
        
        if let model = self.model {
            
            let op1 = try! model.prediction(input: TinyVitInput(input_1: imOnePrepared!))
            let op2 = try! model.prediction(input: TinyVitInput(input_1: imTwoPrepared!))
            
            let v1 = VectorUtility.getArray(forMDarray: op1.output)
            let v2 = VectorUtility.getArray(forMDarray: op2.output)
            
            if ctype == .Distance {
                return VectorUtility.cosineDifference(a: v1, b: v2)
            }
            return VectorUtility.cosineSimilarity(a: v1, b: v2)
            
        }
        
        return -100.0
    }
    
    
    public func identifyRoom(withFrame frame: UIImage, forDirection direction: String, usingGraph graph: FloorGraph) async -> String {
        
        // obtain list of rooms with matching direction and images for that direction
        var rooms = [(String, UIImage)]()
        
        for roomName in graph.nodeStorage.keys {
            // obtain room graph from node storage using iterated name.
            // then obtain thr image using the direction map that matches the current direction
            //let nodeIdForRoom = graph.nodeStorage[roomName]!.directonMap[direction]!
            //let roomIm = graph.nodeStorage[roomName]!.nodeStorage[nodeIdForRoom]!.im!
            guard let roomNode = graph.nodeStorage[roomName] else {
                return ""
            }
            
            guard let nodeIdForRoom = roomNode.directonMap[direction] else {
                return ""
            }
            
            let roomIm = roomNode.nodeStorage[nodeIdForRoom]!.im!
            rooms.append((roomName, roomIm))
        }
        
        
        var maxSimilarity = Float(-100.0)
        var currentRoomWinner = "None"
        
        for room in rooms {
            var similarity = self.similarityBetween(imageOne: frame, andImageTwo: room.1)
            if similarity > maxSimilarity {
                currentRoomWinner = room.0
                maxSimilarity = similarity
            }
        }
        return currentRoomWinner
    }
}
