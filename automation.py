#!/usr/bin/env python3

import os
import sys
import random
import requests
import json
import time

MODEL = 'openai/gpt-oss-20b' # reasoning (default)
#MODEL = 'mistralai/magistral-small-2509 (reason)' #reasoning 



#MODEL = 'google/Gemma-3-27b' # non-explicit reasoning 
#MODEL = 'mistralai/magistral-small-2509' #non-explicit reasoning 
#MODEL = 'microsoft/phi-4' #non-explicit reasoning

"""
Template for basic questions (right or left):
===
I am currently in Room {roomName}
facing wall {currentState!.wallId}, 
which is {currentState!.direction}. 
I am looking to my {headPose.rawValue}. 
Which wall in this room is to my {headPose.rawValue}? 
Provide the scene description.



Template for basic questions (behind):
===
I am currently in Room {roomName} facing wall 
{currentState!.wallId}, which is {currentState!.direction}. 
What is behind me? Provide the scene description.


Template for basic questions (in front):
===
I am currently in Room {roomName} facing wall {currentState!.wallId}, 
which is {currentState!.direction}. What is directly in front of me? 
Provide the scene description.
"""
def basic_query(room_name, wall_state_id, current_direction, head_pose):

	prompt = ""
	if head_pose == "Right" or head_pose == "Left": # nod left or right sim
		prompt = f"I am currently in Room {room_name} facing wall {wall_state_id}, which is {current_direction}. I am looking to my {head_pose}. Which wall in this room is to my {head_pose}? Provide the scene description."
	if head_pose == "Up": # nod upward sim
		prompt = f"I am currently in Room {room_name} facing wall {wall_state_id}, which is {current_direction}. What is behind me? Provide the scene description."
	if head_pose == "Down": # nod downward sim
		prompt = f"I am currently in Room {room_name} facing wall {wall_state_id}, which is {current_direction}. What is directly in front of me? Provide the scene description."

	return prompt


"""
Template for advanced requests:


 "I am currently in Room {roomName}
  facing wall {currentState!.wallId}, 
  {currentState!.direction}. 
  I am looking {headPose.rawValue}. 
  {query}"
"""
def adv_query(room_name, wall_state_id, current_direction, query):
	prompt = f"I am currently in Room {room_name} facing wall {wall_state_id}, which is {current_direction}. {query}"
	return prompt


"""
Template for system role:

You are given a description of a building's floor layout. 
These descriptions include room names, their adjacent rooms, the information for each room containing scene descriptions, 
direction and wall adjacency information. Using this layout description as context, answer all questions asked to you as 
accurately as possible. Pay attention to the relationships between walls and where you are told the user is. Use only the 
context. 

\nContext:\n

graph.getGraphNL()
"""


context = """
Room Alpha has 2 neighboring rooms:Neighbor Room Beta. Beta's Southwest connects to Alpha's Northeast.Neighbor Room Charlie. Charlie's Southeast connects to Alpha's Northwest.
Room Alpha Internal Details: Wall 0 has 2 neighboring walls: Wall 1 (to its right) and Wall 3 (to its left)
Wall 0 faces Northeast. Wall 0's scene description: This scene depicts an electric keyboard with two stacks of music on it below a diploma and a poster. 
Wall 1 has 2 neighboring walls: Wall 0 (to its left) and Wall 2 (to its right)
Wall 1 faces Southeast. Wall 1's scene description: The scene depicts a window with blue curtains hanging on the left side.  A bright, sunny day is visible through the glass panes of the window. Beyond the window, a fence and trees are present in the outdoor scene. The sunlight creates distinct shadows on the glass, adding depth to the overall composition of the scene.
Wall 2 has 2 neighboring walls: Wall 1 (to its left) and Wall 3 (to its right)
Wall 2 faces Southwest. Wall 2's scene description: The scene displays a light blue wall with two white magnetic boards mounted vertically. Alpha board contains handwritten notes and diagrams in blue marker, likely related to a study session or project. Below the board is a large map of the United States, featuring an elevation-based color scheme. A small magnetic clip board is positiAlphad at the bottom of the scene, holding a sheet of paper with more handwritten notes.
Wall 3 has 2 neighboring walls: Wall 2 (to its left) and Wall 0 (to its right)
Wall 3 faces Northwest. Wall 3's scene description: The scene features a light blue wall with a dark brown beam running horizontally across it. A framed print depicting a stylized, elongated bridge is prominently displayed on the wall. To the right of the frame sits a shelf holding various objects, including a small animal figurine and several bottles. A partially visible bookshelf is located on the right side of the scene, adding depth to the composition.

---
Room Beta has 2 neighboring rooms:Neighbor Room Echo. Echo's Southeast connects to Beta's Northwest.Neighbor Room Alpha. Alpha's Northeast connects to Beta's Southwest.
Room Beta Internal Details: Wall 0 has 2 neighboring walls: Wall 1 (to its right) and Wall 3 (to its left)
Wall 0 faces Northeast. Wall 0's scene description: The scene depicts a dark-colored television mounted on a plain white wall. A person is reflected in the darkened screen, appearing to be holding a tablet device. The reflection shows a room with furniture and a doorway. Cables are attached to the television, suggesting it is connected to an electrical outlet.
Wall 1 has 2 neighboring walls: Wall 0 (to its left) and Wall 2 (to its right)
Wall 1 faces Southeast. Wall 1's scene description: The scene depicts a window with white curtains hanging on a rod. Through the window, there is a blurred outdoor scene of trees and foliage. The glass appears to have a frosted or privacy film applied, creating a hazy effect. Sunlight streams through the window, illuminating the interior and casting shadows on the wall.
Wall 2 has 2 neighboring walls: Wall 1 (to its left) and Wall 3 (to its right)
Wall 2 faces Southwest. Wall 2's scene description: The scene depicts a gray metal shelving unit mounted on a light beige wall. The shelves are tiered, providing two levels for storage or display items. A black appliance sits on the lower shelf of the shelving unit, partially obscured by the wall. To the left of the scene is a doorway leading into another room with cabinets and a door.
Wall 3 has 2 neighboring walls: Wall 2 (to its left) and Wall 0 (to its right)
Wall 3 faces Northwest. Wall 3's scene description: The scene depicts a wall with Charlie black floating shelves arranged in a stacked formation.  Each shelf is supported by small black brackets and appears to be holding various items. A lamp with a flexible neck stands on the right side of the scene, providing illumination.  A small white box is positiAlphad on Alpha of the shelves, adding a touch of color to the minimalist arrangement.

---
Room Charlie has 2 neighboring rooms:Neighbor Room Alpha. Alpha's Northwest connects to Charlie's Southeast.Neighbor Room Delta. Delta's Southeast connects to Charlie's Northwest.
Room Charlie Internal Details: Wall 0 has 2 neighboring walls: Wall 1 (to its right) and Wall 3 (to its left)
Wall 0 faces Northeast. Wall 0's scene description: This scene depicts a portion of an interior hallway. A pale yellow wall is visible, adorned with several framed artworks and a light switch.  A dark wooden staircase leads upwards to another level, supported by a railing.
Wall 1 has 2 neighboring walls: Wall 0 (to its left) and Wall 2 (to its right)
Wall 1 faces Southeast. Wall 1's scene description: The scene depicts a wall with several decorative items arranged on it. A vibrant, abstract vertical painting dominates the left side of the wall with a colorful landscape design. To the right is a small, black metal key holder with several keys attached. A vintage-looking wooden frame containing a small figurine is positiAlphad near the bottom right corner of the wall.
Wall 2 has 2 neighboring walls: Wall 1 (to its left) and Wall 3 (to its right)
Wall 2 faces Southwest. Wall 2's scene description: The scene depicts a pair of white glass doors with a mesh screen. Outside, there is a residential building complex. A potted plant sits on the floor near the doors, adding a touch of greenery to the interior space. The overall scene suggests a comfortable and well-lit living area with an outdoor view.
Wall 3 has 2 neighboring walls: Wall 2 (to its left) and Wall 0 (to its right)
Wall 3 faces Northwest. Wall 3's scene description: This scene showcases a decorated wall shelf with various decorative objects. Several framed photographs and small sculptures are arranged alongside a table. The wall also features a decorative metal sign.

---
Room Delta has 2 neighboring rooms:Neighbor Room Charlie. Charlie's Northwest connects to Delta's Southeast.Neighbor Room Echo. Echo's Southwest connects to Delta's Northeast.
Room Delta Internal Details: Wall 0 has 2 neighboring walls: Wall 1 (to its right) and Wall 3 (to its left)
Wall 0 faces Northeast. Wall 0's scene description: The scene depicts a room with a dark gray wall as the primary backdrop. A small, white light fixture is mounted on the ceiling near the top center of the wall.  A framed bulletin board hangs vertically in the middle of the wall, displaying various items. A small, black picture frame is positiAlphad to the right of the bulletin board, alongside a dark bookshelf.
Wall 1 has 2 neighboring walls: Wall 0 (to its left) and Wall 2 (to its right)
Wall 1 faces Southeast. Wall 1's scene description: The scene depicts a hallway leading into a living room. A white doorframe separates the hallway from the main room, creating a distinct division. Within the living room, there are several framed artworks and furniture pieces visible. A dark-colored reading chair is situated in the corner.
Wall 2 has 2 neighboring walls: Wall 1 (to its left) and Wall 3 (to its right)
Wall 2 faces Southwest. Wall 2's scene description: The scene features a gray wall with several decorative elements. A metal sconce holds a white bowl, positiAlphad above a small framed film reel display. To the right of the sconce is a framed print depicting a black and white drawing of a landscape. The overall composition suggests a simple, somewhat rustic interior design aesthetic with a focus on visual interest.
Wall 3 has 2 neighboring walls: Wall 2 (to its left) and Wall 0 (to its right)
Wall 3 faces Northwest. Wall 3's scene description: This scene depicts a home entertainment area with a prominent white television. The television is adorned with a floral arrangement of greenery and white flowers. The wall behind the television is painted in a muted brown color, providing a neutral backdrop. A small red object sits to the left of the pillar, adding a pop of color to the overall composition.

---
Room Echo has 2 neighboring rooms:Neighbor Room Beta. Beta's Northwest connects to Echo's Southeast.Neighbor Room Delta. Delta's Northeast connects to Echo's Southwest.
Room Echo Internal Details: Wall 0 has 2 neighboring walls: Wall 1 (to its right) and Wall 3 (to its left)
Wall 0 faces Northeast. Wall 0's scene description: The scene depicts a room with a beige wall and a window. A purple curtain hangs above the window, partially obscuring it. Outside the window, there is a view of trees and foliage in daylight. A shelf holds decorative items like a framed print, candle holder, and small pitcher.
Wall 1 has 2 neighboring walls: Wall 0 (to its left) and Wall 2 (to its right)
Wall 1 faces Southeast. Wall 1's scene description: This scene presents a plain, white wall with a noticeable vertical line running down its center. The wall appears to be freshly painted and has a smooth, even texture. A small dark spot is present near the bottom of the wall’s center. The lighting in this scene appears to be soft and diffused, creating minimal shadows.
Wall 2 has 2 neighboring walls: Wall 1 (to its left) and Wall 3 (to its right)
Wall 2 faces Southwest. Wall 2's scene description: This scene depicts a narrow hallway within a residential building. A dark doorway leads into another room, creating a sense of depth and perspective. To the right, a coat rack holds several dark jackets and bags, adding functional detail to the space.  A framed artwork hangs on the wall beside the doorway, contributing to the overall aesthetic of the hallway.
Wall 3 has 2 neighboring walls: Wall 2 (to its left) and Wall 0 (to its right)
Wall 3 faces Northwest. Wall 3's scene description: The scene depicts a flat-screen television mounted on a beige wall. A small, dark figure is visible on the screen of the television. Below the television sits a desk with various items, including a small statue and a blue ball. The wall itself appears to be part of a room with wooden furniture visible in the background.

---
"""

if MODEL == "mistralai/magistral-small-2509 (reason)":
	system_prompt = f"First draft your thinking process (inner monologue) until you arrive at a response. Format your response using Markdown, and use LaTeX for any mathematical equations. Write both your thoughts and the response in the same language as the input. Your thinking process must follow the template below:[THINK]Your thoughts or/and draft, like working through an exercise on scratch paper. Be as casual and as long as you want until you are confident to generate the response. Use the same language as the input.[/THINK]Here, provide a self-contained response. You are given a description of a building's floor layout. These descriptions include room names, their adjacent rooms, the information for each room containing scene descriptions, direction and wall adjacency information. Using this layout description as context, answer all questions asked to you as accurately as possible. Pay attention to the relationships between walls and where you are told the user is. Use only the context. \nContext:\n{context}"
	MODEL = 'mistralai/magistral-small-2509'
else: 
	system_prompt = f"You are given a description of a building's floor layout. These descriptions include room names, their adjacent rooms, the information for each room containing scene descriptions, direction and wall adjacency information. Using this layout description as context, answer all questions asked to you as accurately as possible. Pay attention to the relationships between walls and where you are told the user is. Use only the context. \nContext:\n{context}"


# Template for simulated infos:
# room: {id: dir}
# this is not the same way the data structure is created inside the app itself, which does contain the descriptions. The context, however, is true-to-template.

graph_sim = {
	"Alpha": {0 : ["Northeast"], 1 : ["Southeast"], 2 : ["Southwest"], 3 : ["Northwest"]},
	"Beta": {0 : ["Northeast"], 1 : ["Southeast"], 2 : ["Southwest"], 3 : ["Northwest"]},
	"Delta": {0 : ["Northeast"], 1 : ["Southeast"], 2 : ["Southwest"], 3 : ["Northwest"]},
	"Charlie": {0 : ["Northeast"], 1 : ["Southeast"], 2 : ["Southwest"], 3 : ["Northwest"]},
	"Echo": {0 : ["Northeast"], 1 : ["Southeast"], 2 : ["Southwest"], 3 : ["Northwest"]},

}



llm_ip = "http://<local_ip>:11434/v1/chat/completions"

def send_request(query):


	agent_response = ""

	heads = {
    'Content-Type':'application/json',
    'Accept':'*/*'
	}

	chat_history = []
	chat_history.append({'role': 'system', 'content' : [{'type': 'text', 'text' : f'{system_prompt}'}]})
	
	chat_history.append({'role': 'user', 'content': f'{query}'})
	
	request = {'model': MODEL, 'messages': chat_history}



	try:
		resp = requests.post(llm_ip, json=request, headers=heads)
		agent_response = resp.json()['choices'][0]['message']['content']
	
	except Exception as e:
		print(f'Error: {e}')

	return agent_response



def fun_request():
	agent_response = ""

	heads = {
    'Content-Type':'application/json',
    'Accept':'*/*'
	}

	chat_history = []
	chat_history.append({'role': 'system', 'content' : [{'type': 'text', 'text' : f'{system_prompt}'}]})
	chat_history.append({'role': 'user', 'content': f'Can you draw an ascii map of the layout? Draw them as a grid, do not worry about arrows.'})

	request = {'model': MODEL, 'messages': chat_history}



	try:
		resp = requests.post(llm_ip, json=request, headers=heads)
		agent_response = resp.json()['choices'][0]['message']['content']
	except Exception as e:
		print(f'Error: {e}')

	return agent_response


def begin_advanced_sim(room_name, rounds=6):
	start_state = -1 
	graph_selection = graph_sim[room_name]

	head_poses = ["Left", "Right", "Down", "Up"]

	direction_abbrev_map = {"Northwest":"NW","Northeast":"NE","Southwest":"SW","Southeast":"SE"}

	states = [0,1,2,3]
	#random.shuffle(states)
	

	for i in range(rounds):
		output_string = ""
		print(f"Trial: {i}")
		start_state = (start_state + 1) % 4 # This is just to shuffle from 0 to 3 and back again fairly.

		current_state = states[start_state]
		direction = graph_selection[current_state][0]

		output_string += f'Queries: ADVANCED\n'
		output_string += f'Room: {room_name}\n'
		output_string += f'Direction: {direction_abbrev_map[direction]}\n'
		output_string += f'Model: {MODEL}\n\n'
		print(output_string)

		resps = advanced_requests(room_name, current_state, direction)
		output_string += resps 

		model_out_name = MODEL.replace("/", "-")
		with open(f'{room_name}_{model_out_name}_ADVANCED_Trial_{i}.txt', "w") as outfile:
			outfile.write(output_string)






def advanced_requests(room_name, wall_state_id, current_direction):
	
	adv_output_string = ""

	rs = ['Alpha', 'Charlie', 'Delta', 'Beta', 'study', 'bathroom', 'Echo', 'living']
	q = ['What room is behind me?', 'What room is to my left?', 'What room is to my right?', 'What room is in front of me?', 'If I were in the room to my left with the same orientation as now, what wall in that room would be to my right?', 'If I were in the room to my left with the same orientation as now, what wall in that room would be to my left?', 'How many rooms away is room X?', 'Where is room X relative to me?', 'What wall would I be facing if I turned left 3 times?', 'What room would I be facing if I turned right 4 times?']
	i = 1
	for query in q[:4]:
		adv_output_string += f"[Q #{i}]\n"
		if query == 'How many rooms away is room X?':
			ip = random.choice(rs)
			query = f"How many rooms away is room {ip}?"

		if query ==  'Where is room X relative to me?':
			ip = random.choice(rs)
			query = f"Where is room {ip} relative to me?"


		model_q = adv_query(room_name, wall_state_id, current_direction, query)
		resp = send_request(model_q)


		adv_output_string += model_q + "\n\n"
		adv_output_string += resp + "\n"
		adv_output_string += '----------------------\n'
		i += 1

	return adv_output_string



def begin_sim(room_name, rounds=6):

	start_state = -1
	graph_selection = graph_sim[room_name]

	head_poses = ["Left", "Right", "Down", "Up"]

	direction_abbrev_map = {"Northwest":"NW","Northeast":"NE","Southwest":"SW","Southeast":"SE"}

	states = [0,1,2,3]
	#random.shuffle(states)

	
	for i in range(1, rounds+1):
		output_string = ""
		print(f"Trial: {i}")
		start_state = (start_state + 1) % 4 # This is just to shuffle from 0 to 3 and back again fairly.

		current_state = states[start_state]
		direction = graph_selection[current_state][0]

		output_string = f'Queries: BASIC'
		output_string += f'\nRoom: {room_name}'
		output_string += f'\nDirection: {direction_abbrev_map[direction]}'
		output_string += f'\nModel: {MODEL}'
		output_string += f'\n'

		q1_left = basic_query(room_name, current_state, direction, head_poses[0])
		q2_right = basic_query(room_name, current_state, direction, head_poses[1])
		q3_down_forward = basic_query(room_name, current_state, direction, head_poses[2])
		q4_up_backward = basic_query(room_name, current_state, direction, head_poses[3])
		

		resp_left = send_request(q1_left)
		print('.')
		resp_right = send_request(q2_right)
		print('.')
		resp_back = send_request(q4_up_backward)
		print('.')
		resp_forward = send_request(q3_down_forward)
		print('.')

		# Print out responses
		output_string += q1_left + '\n\n'
		output_string += resp_left + '\n\n'
		output_string += '======================================================\n'
		output_string += q2_right + '\n\n'
		output_string += resp_right + '\n\n'
		output_string += '======================================================\n'
		output_string += q3_down_forward + '\n\n'
		output_string += resp_forward + '\n\n'
		output_string += '======================================================\n'
		output_string += q4_up_backward + '\n\n'
		output_string += resp_back + '\n\n'
		output_string += "-=-=-=-=-=-=-=-=-=-=- [End Responses] -=-=-=-=-=-=-=-=-=-=-\n"

		model_out_name = MODEL.replace("/", "-")
		with open(f'{room_name}_{model_out_name}_BASIC_Trial_{i}.txt', 'w') as outfile:
			outfile.write(output_string)





rooms = ['Alpha']

for room in rooms:
	print(f'Room ---- {room} [basic sim]')
	begin_sim('Alpha', rounds=1)

for room in rooms:	
	print(f"Room ---- {room} [advanced sim]")
	begin_advanced_sim('Alpha', rounds=1)
	print(f"Breathing for a few minutes.")




















