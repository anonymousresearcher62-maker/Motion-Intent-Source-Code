# Motion Intent & LLM Orientation and Mapped Understanding
Research Work Application for Motion Intent Paper


This application is a proof-of-concept for interacting with LLMs using wearable devices and abstracting the world into graph-based representations for easy interactions with LLMs.
As I am not creating a "production-ready" app, there are many strange bugs and corner cases I really want to fix. 

To add in some of the more nitty-gritty "how it works" stuff (e.g., speech recognition), I used some code from libraries and samples I found as I worked on it. I have annotated where I have used them in the code itself, but I'd like to give them credit here as well:


TODO: ADD LINKS


Thanks!! 

App Guide
---

* APMotionCollection: The primary test app for AirPod motion and head pose detection. 
* Wayfinding - MI: The app that lets you build the world-to-graph abstraction model. 

---



Some thoughts on improvements I'd like to make in the future:

TL;DR Fully on-device models (VLLM and LLM), provided enough RAM. 

This app, and it's work, largely centers on using ML on the edge or even on-device. As years progress, hardware gets more and more powerful thus enabling us to run much more intense models right on our phones. Obviously, however, they can only get so powerful before it becomes a fully fledged computer. I used, by today's standards, an outdated (M1) iPad with 8GB of RAM. other models even come with 16GB of RAM - woah! 

That being said, it's not crazy to think about fitting all these models on an iPad (or any other smart device, rather - I Just chose an iPad) with enough compute capability. Android, for example, now has Gemma LLMs running on-device as well (https://www.datacamp.com/tutorial/gemma-3n). I chose to write this in a Playground, which limited me in some of the things I wanted to do because it doesn't have the same full capacity as Xcode -- rapid prototyping vs. connecting, compiling, enabling developer mode, restricted to 7 days per deployment, etc. 

If someday I decide to reimplement this app, it'd be through Xcode's full capacity to allow me to use models like Gemma MLX on iOS/iPad OS directly. There are plenty of quantized versions of these models also available! 
I could actually convert a hugginface model to CoreML like they did on the guide with Mistral, BUT it is a lot more involved than it initially seemed; while I successfully did it for Gemma, the generation step simply just did not work even if the model loaded in memory correctly. Anyway, it's a good future direction. 

The issue is that with only 8GB of RAM I'd be hard pressed to think it could survive eventually being killed by the OS. Gemma by itself uses at least ~4GB of memory on the low end, and OpenAI's model wouldn't be nearly possible to do it on an iPad at all. So, for now, division of responsibilities and using a capable machine that's still consumer level served the research perfectly. 

---

## Wishlist Features

 Additionally, I think that it would be cool to, instead of algorithmically, use the LLMs to generate the NLP from the graph data structure. However, there are a few issues with that:
 1. It's probably akin to using AI just for the sake of it, no matter how cool it is. I think it's would be neat as far as end-to-end is concerned, though.
 2. For obvious reasons, you can't just take the source code and turn it into NLP without having access to the compilation process. Because I use playgrounds, I don't have the same access to the magical code compilation that Xcode would provide if I were to instrument with, say, Frida.

 3. Room graph reset option.
 4. Graph serialization for persistent storage.
 5. Room Graph Replacement and/or refinement. Maybe collaborative where other people using other devices can share room graphs and be crowd-sourced (inspired by my previous works).
 6. As an extention to #5, if the scene description is very poor, or in fact it is dark (i.e., night time), we can use retrieval from stored nodes as supplementary information. 
 7. Improved Graph Linking. I want to put a drag-and-drop box rearrangment approach where the directions of the rooms snap into each other instead of being so manual.
---

## Known Issues & Bugs:
* Despite my best efforts, it seems I need more practice with certain framework lifecycles and memory management. Here I outline some known bugs I have encountered in my experiments.
  
1. During the state mis/alignment events, there may be a crash; this happens most often if you move the whole device while in motion intent mode. I've yet to pinpoint this, as playgrounds doesn't have very good error reporting. It seems the best workaround is just going back to the home screen and then re-entering the motion intent mode. If it doesn't crash, I added a "refresh" button to reset the headphone motion manager. Originally I had a permanent state change but that caused too many issues. 
3. Rarely, the compass direction doesn't reset properly and ends up cutting off the enrollment process early (usually two nodes instead of four). This doesn't happen TOO often, but I need to implement a better way to completely reset those states. There seems to be an error in the way I maintain lifecycle in the navigation
   stack. I changed it to have a "go-to-home" which resets the enrollment but not the location manager. 
   
5. Attempting room identification can fail when the current location does not match those found in the enrolled nodes. For example, if you happen to face "North" and none of the nodes in the graph face "North", then it will fail. For this reason, I added an override to manually input the correct room for experimentation purposes. Additionally, room identification can be wrong (but not fail) if two scenes are far too similar and face the same direction (as they are based on cosine similarity). One thing I did do was add better safety handling on the graph indexing to prevent crashes. Generally I disregard certain boundary tests if I am building apps only for myself. However, it got rather annoying so I decided to add more safety handling.
   
7. Sometimes if you have not launched the graph from scratch and go back to the main menu and back into "Navigate" view, the app will start issuing two or more requests at once causing overlapping assistant responses.

8. In certain locations, the magnetic heading readings are not inherently consistent and this is just implementation weirdness on my part. That is, not all rooms face the same directions, which is strange but it doesn't detract from functionality (aside from room ID using the graph or having a rougher time connecting the rooms). I need to come up with a tighter way of determining the heading (i.e. N/S/E/W). A workaround I thought about was using the first heading as a reference of "North" and anything +90 is the next set of directions, with a tolerance. I will leave this to future fixes. 
   
    
---
## Running non-traditional coreml models on-devce.

Playgrounds is great but it comes with several limits. In order to run an already-compiled model on Plagrounds, you need to put that on the device. However, in the Playground resources, it becomes a folder structure. I had to convert ViT from huggingface to CoreML (creating a mlpackage) after modifying it to extract embeddings from inputs. I then compiled it into mlmodelc using Xcode on the laptop. Pretty compilcated. 
I've provided the mlmodelc ViT I modified to extract embeddings here, but you will need to zip it and download it into Playgrounds yourself (which is easy). 


Apple’s Swift playgrounds on iPad is a strange place to deal with different constraints. After several hours of tweaking and workarounds, the best way to run a mlmodelc file on Swift playgrounds for ipad that has originated from an mlprogram is to first follow the steps to compile it on a mac:

- Open your mlprogram in an xcode project (or drag and drop into the xcode app);
- build the project;
- Get the auto-generated class;
- Under your product binary, find the mlmodelc file and zip it.

Playgrounds does not itself recognize the folder structure for mlmodelc, so the workaround is to download the mlmodelc directory into your app’s sandbox in one of two ways:

1. Import it from the files app on iPad (a little harder)
2. Download it from a little web server.

I chose the web server. In python, you can launch a very simple http server. Zip up your mlmodelc file, and launch the web server from within that directory. Then, you can use URLSession to download the model.




---

This software, as indicated by the license, is fully open source and free to use so we can learn and contribute together.

If it helped in your research, please kindly cite our work 😀. 

TODO: ADD CITATION BLOCK
