import SwiftUI

enum LLMType: String {
    case Gemma = "mlx-community/gemma-3-4b-it-8bit" //"google/gemma-3-4b"
    case GemmaLG = "google/Gemma-3-27b"
    case OpenAI = "openai/gpt-oss-20b"
    case Mistral = "mistralai/magistral-small-2509"
    case MistralReason = "mistral_special"
    case Phi = "microsoft/phi-4"
}


struct LLMAPIResponse: Decodable {
    
    struct ChatChoices: Decodable {
        
        struct ChatMessage: Decodable {
            let role: String
            let content: String
            let tool_calls: [String]?
        }
        
        let index: Int
        let message: ChatMessage
        let logprobs: String?
        let finish_reason: String
    }
    
    struct ChatUsage: Decodable {
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
    }
    
    struct ChatStats: Decodable {
        
    }
    
    let id: String
    let object: String
    let created: Int
    let model: String
    
    
    let choices: [ChatChoices]
    let usage: ChatUsage
    let stats: ChatStats?
    
}

protocol LLMRequest {
    
    func makeAsyncRequest(forImage img: UIImage?, withPrompt prompt: String) async -> String
    
}

struct LLMIP {
    static let ip = "http://<local_ip>:11434"
}


 
class LLMNavAPI {
    
    var urlrequest: URLRequest
    var parameters = [String:Any]()
    var chatHistory = [[String:Any]]()
    
    let customSession: URLSession
    var sysPrompt: String?
    init(withGraph graph: FloorGraph) {
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 5400
        sessionConfig.timeoutIntervalForResource = 5400
        
        self.customSession = URLSession(configuration: sessionConfig)
        
        
        self.urlrequest = URLRequest(url: URL(string: "\(LLMIP.ip)/v1/chat/completions")!)
        self.urlrequest.httpMethod = "POST"
        self.urlrequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        self.urlrequest.setValue("*/*", forHTTPHeaderField: "Accept")
        
        let mdl = LLMType.GemmaLG.rawValue
        
        
        
        parameters["model"] = mdl
        if mdl == LLMType.MistralReason.rawValue {
            parameters["model"]  = LLMType.Mistral.rawValue
        }
        
        
        
        // system prompt / role will enable us to bake in the graph to the
        // model's behavior. This helps us indicate context.
         sysPrompt = "You are given a description of a building's floor layout. These descriptions include room names, their adjacent rooms, the information for each room containing scene descriptions, direction and wall adjacency information. Using this layout description as context, answer all questions asked to you as accurately as possible. Pay attention to the relationships between walls and where you are told the user is. Use only the context. \nContext:\n\(graph.getGraphNL())"
        
        
        if mdl == LLMType.MistralReason.rawValue {
            sysPrompt = "First draft your thinking process (inner monologue) until you arrive at a response. Format your response using Markdown, and use LaTeX for any mathematical equations. Write both your thoughts and the response in the same language as the input. Your thinking process must follow the template below:[THINK]Your thoughts or/and draft, like working through an exercise on scratch paper. Be as casual and as long as you want until you are confident to generate the response. Use the same language as the input.[/THINK]Here, provide a self-contained response. You are given a description of a building's floor layout. These descriptions include room names, their adjacent rooms, the information for each room containing scene descriptions, direction and wall adjacency information. Using this layout description as context, answer all questions asked to you as accurately as possible. Pay attention to the relationships between walls and where you are told the user is. Use only the context. \nContext:\n\(graph.getGraphNL())"
        }
        
        
        chatHistory.append(["role" : "system", "content" :  [["type" : "text", "text": sysPrompt]]])
        
        
        
        self.urlrequest.timeoutInterval = 5400
        
        
    }
    
    func resetHistory() {
        chatHistory.removeAll()
        chatHistory.append(["role" : "system", "content" :  [["type" : "text", "text": sysPrompt]]])
    }
    
    func makeAsyncRequest(withPrompt prompt: String) async -> String {
        
        let defaultDes = "Failed."
        
        chatHistory.append(["role" : "user", "content" : prompt])
        parameters["messages"] = chatHistory
        // prepare request before  starting the task
        let bodyData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        self.urlrequest.httpBody = bodyData
        
        do {
            let (data, _) = try await customSession.data(for: self.urlrequest)
            let decdedResponse = try JSONDecoder().decode(LLMAPIResponse.self, from: data)
            //print(decdedResponse.choices[0].message.content)
            self.resetHistory()
            if (chatHistory.count == 1) {
                print("Warning! Chat history is not 1.")
            }
            
            var response = decdedResponse.choices[0].message.content
            
            return response
        } catch let err {
            //print("Error obtaining data. \(err)")
            self.resetHistory()
            if (chatHistory.count == 1) {
                print("Warning! Chat history is not 1.")
            }
        }
        
        return defaultDes
        
    }
    
    
    
    
}




class LLMAPIMode: LLMRequest {
    
    var urlrequest: URLRequest
    var parameters = [String:Any]()
    var chatHistory = [[String:Any]]()
    
    let customSession: URLSession
    
    init() {
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 5400
        sessionConfig.timeoutIntervalForResource = 5400
        
        self.customSession = URLSession(configuration: sessionConfig)
        
        
        self.urlrequest = URLRequest(url: URL(string: "\(LLMIP.ip)/v1/chat/completions")!)
        self.urlrequest.httpMethod = "POST"
        self.urlrequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        self.urlrequest.setValue("*/*", forHTTPHeaderField: "Accept")
        
        parameters["model"] = LLMType.Gemma.rawValue
        let sysPrompt = "You are a helpful seeing assistant. Provide succinct but accurate answers to questions. Your answers should be four sentences long. Do not restate the question. Replace the word image with the word scene in your responses."
       // let sysPrompt = "You are a helpful seeing assistant. Be as detailed as possible. Your answers can be as long as needed to describe it. Do not restate the question. Replace the word image with the word scene in your responses."
        
        chatHistory.append(["role" : "system", "content" :  [["type" : "text", "text": sysPrompt]]])
        
        self.urlrequest.timeoutInterval = 5400
        
        
    }
    
    
    func makeAsyncRequest(forImage img: UIImage? = nil, withPrompt prompt: String) async -> String {
        
        let defaultDes = "Failed."
        
        
        if let img = img {
            
            //encode image to base64
            let encoded = img.jpegData(compressionQuality: 1)?.base64EncodedString()
            guard let encoded = encoded else {
                print("Error encoding image to base64!")
                return "Failed"
            }
            let image_prompt = [["type": "image_url", "image_url": ["url" : "data:image/jpeg;base64,\(encoded)"]], ["type" : "text", "text" : prompt]]
            chatHistory.append(["role" : "user", "content" : image_prompt])
            
        } else {
            chatHistory.append(["role" : "user", "content" : prompt])
        }
        
        parameters["messages"] = chatHistory
        // prepare request before  starting the task
        let bodyData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        self.urlrequest.httpBody = bodyData
        
        do {
            let (data, _) = try await customSession.data(for: self.urlrequest)
            let decdedResponse = try JSONDecoder().decode(LLMAPIResponse.self, from: data)
            //print(decdedResponse.choices[0].message.content)
            chatHistory.popLast()
            assert(chatHistory.count == 1)
            //print(decdedResponse.response)
            return decdedResponse.choices[0].message.content
        } catch let err {
            //print("Error obtaining data. \(err)")
            chatHistory.popLast()
            assert(chatHistory.count == 1)
        }
        
        return defaultDes
        
    }

    
    
    
}
