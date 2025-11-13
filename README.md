# Motion Intent & LLM Orientation Body-Relative Guidance Understanding
Research Work Application for Body-Relative Guidance LLM Paper

This application is a proof-of-concept for interacting with LLMs using wearable devices and abstracting the world into graph-based representations for easy interactions with LLMs.
There are various bugs and corner cases I would like to fix as and if this app is iterated upon. First, here is the app guide.


App Guide
---

* APMotionCollection: The primary test app for AirPod motion and head pose detection. 
* Wayfinding - MI: The app that lets you build the world-to-graph abstraction model. 
---



Some thoughts on improvements I'd like to make in the future:

TL;DR Fully on-device models (VLLM and LLM), provided enough RAM. 

This app, and it's work, largely centers on using ML on the edge or even on-device. As years progress, hardware gets more and more powerful thus enabling us to run much more intense models right on our phones. Obviously, however, they can only get so powerful before it becomes a fully fledged computer. I used, by today's standards, an outdated (M1) iPad with 8GB of RAM.

That being said, it's not crazy to think about fitting all these models on an iPad (or any other smart device, rather - I Just chose an iPad) with enough compute capability. Android, for example, now has Gemma LLMs running on-device as well (https://www.datacamp.com/tutorial/gemma-3n). I chose to write this in a Playground, which limited me in some of the things I wanted to do because it doesn't have the same full capacity as Xcode -- rapid prototyping vs. connecting, compiling, enabling developer mode, restricted to 7 days per deployment, etc. Newer devices come with enough RAM to fit these model now too.

With enough resources for re-implementation, it'd be through Xcode to allow me to use models like Gemma MLX on iOS/iPad OS directly. There are plenty of quantized versions of these models now available! 
The issue  with only 8GB of RAM, it's reasonable to think it could eventually be killed by the OS. Gemma by itself uses at least ~4GB of memory on the low end, and OpenAI's model wouldn't be nearly possible to do it on an iPad at all (at least 12 GB just to load). So, for now, division of responsibilities and using a capable machine that's still consumer level served the research perfectly. 

---

 ## Wishlist Directions

 1. On-edge graph serialization for persistent storage.
 2. Room Graph hot-swapping and/or refinement. Maybe collaborative where other people using other devices can share room graphs and be crowd-sourced.
 3. As an extention to #2, if the scene description is very poor, or in fact it is dark (i.e., night time), we can use retrieval from stored nodes as supplementary information. 
 4. Improved Graph Linking: Grag-and-drop box rearrangment approach where the directions of the rooms snap into each other instead of being highly manual (which is why it was not measured as part of efficiency).
---

## Known Issues & Bugs:

To supplement the application, we write a Python simulator for the experiments. Here I outline some known bugs I have encountered in my experiments with the proof-of-concept application. 
  
1. During the state mis/alignment events, there may be a crash; this happens most often if you move the whole device while in motion intent mode. Playgrounds doesn't have very good error reporting. If it doesn't crash, I added a "refresh" button to reset the headphone motion manager. To handle this in the future, we can add a permanent state change to reset the reference frames automatically.
   
2. Rarely, the compass direction doesn't reset properly and ends up cutting off the enrollment process early (usually two nodes instead of four).  There seems to be an error in the way the navigation stack lifecycle is maintained. It now has a "go-to-home" which resets the enrollment to bypass this bug. 
   
3. Sometimes if you have not launched the graph from scratch and go back to the main menu and back into "Navigate" view, the app will start issuing two or more requests at once causing overlapping assistant responses.

--
Research Bugs and Minor Gaps in Approach for the App:
   
1. Room identification can fail when the current location does not match those found in the enrolled nodes. For example, if you happen to face "North" and none of the nodes in the graph face "North", then it will fail. For this reason, I added an override to manually input the correct room for ease-of-experimentation purposes. Additionally, room identification can be wrong (but not fail) if two scenes are far too similar and face the same direction (as they are based on cosine similarity). One thing I did do was add better safety handling on the graph indexing to prevent crashes. As stated in the work, room identification is out of the scope, and this is purely for demonstration purposes for the capabilities of using a graph data structure in this manner. Other works in localization design approaches for pose recovery and also room identification without computer vision.

2. In certain locations, the magnetic heading readings are not inherently consistent and this is just implementation from the angle heuristics. That is, not all rooms face the same directions, which is strange but it doesn't detract from functionality (aside from room ID using the graph or having a rougher time connecting the rooms). The best thing to do is come up with a tighter way of determining the heading (i.e. N/S/E/W). A possibility is using the first heading as a reference of "North" and anything +90 is the next set of directions, with a tolerance, since the angles are always relatively consistent. I will leave this to future implementations. 
   
    
---
## Running non-traditional coreml models on-devce in Playgrounds.

Playgrounds is great but it comes with several limits. In order to run an already-compiled model on Plagrounds, you need to put that on the device. However, in the Playground resources, it becomes a folder structure. I had to convert ViT from huggingface to CoreML (creating a mlpackage) after modifying it to extract embeddings from inputs. I then compiled it into mlmodelc using Xcode.
We provide the mlmodelc ViT I modified to extract embeddings here, but you will need to zip it and download it into Playgrounds yourself. 


The best way to run a mlmodelc file on Swift playgrounds for ipad that has originated from an mlprogram is to first follow the steps to compile it:

- Open your mlprogram in an xcode project (or drag and drop into the xcode app);
- build the project;
- Get the auto-generated class;
- Under your product binary, find the mlmodelc file and zip it.

Playgrounds does not itself recognize the folder structure for mlmodelc, so you must place the mlmodelc directory into your app’s sandbox in one of two ways:

1. Import it from the files.
2. Download it from a web server.

I chose the web server. In python, you can launch a very simple http server. Zip up your mlmodelc file, and launch the web server from within that directory. Then, you can use URLSession to download the model.

---

This software, as indicated by the license, is fully open source and free to use.
