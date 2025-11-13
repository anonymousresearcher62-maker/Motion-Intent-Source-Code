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
    
    init(withGraph graph: FloorGraph) {
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 5400
        sessionConfig.timeoutIntervalForResource = 5400
        
        self.customSession = URLSession(configuration: sessionConfig)
        
        
        self.urlrequest = URLRequest(url: URL(string: "\(LLMIP.ip)/v1/chat/completions")!)
        self.urlrequest.httpMethod = "POST"
        self.urlrequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        self.urlrequest.setValue("*/*", forHTTPHeaderField: "Accept")
        
        let mdl = LLMType.OpenAI.rawValue
        
        
        
        parameters["model"] = mdl
        if mdl == LLMType.MistralReason.rawValue {
            parameters["model"]  = LLMType.Mistral.rawValue
        }
        
        // system prompt / role will enable us to bake in the graph to the
        // model's behavior. This helps us indicate context.
        var sysPrompt = "You are given a description of a room's internal layout in terms of two divisions. These descriptions include division numbers, their adjoining divisions, the information for each division containing scene descriptions, object tags, direction and other wall information. The walls will largely be the same since they are in the *same* room (there are no separate rooms, so treat your answer as such). Using this layout description as context, answer all questions asked to you as accurately as possible. Pay attention to the directional relationships to help make distinctions. Use only the context. \nContext:\n\(graph.getGraphNL())"
        
        
        if mdl == LLMType.MistralReason.rawValue {
            sysPrompt = "First draft your thinking process (inner monologue) until you arrive at a response. Format your response using Markdown, and use LaTeX for any mathematical equations. Write both your thoughts and the response in the same language as the input. Your thinking process must follow the template below:[THINK]Your thoughts or/and draft, like working through an exercise on scratch paper. Be as casual and as long as you want until you are confident to generate the response. Use the same language as the input.[/THINK]Here, provide a self-contained response. You are given a description of a room's internal layout in terms of two divisions. These descriptions include division numbers, their adjoining divisions, the information for each division containing scene descriptions, object tags, direction and other wall information. The walls will largely be the same since they are in the *same* room (there are no separate rooms, so treat your answer as such). Using this layout description as context, answer all questions asked to you as accurately as possible. Pay attention to the directional relationships to help make distinctions. Use only the context.  \nContext:\n\(graph.getGraphNL())"
        }
        
        
        print(graph.getGraphNL())
        
        
        chatHistory.append(["role" : "system", "content" :  [["type" : "text", "text": sysPrompt]]])
        
        
        
        self.urlrequest.timeoutInterval = 5400
        
        
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
            chatHistory.popLast()
            assert(chatHistory.count == 1)
            return decdedResponse.choices[0].message.content
        } catch let err {
            print("Error obtaining data. \(err)")
            chatHistory.popLast()
            assert(chatHistory.count == 1)
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
            print("Error obtaining data. \(err)")
            chatHistory.popLast()
            assert(chatHistory.count == 1)
        }
        
        return defaultDes
        
    }

    
    
    
}
