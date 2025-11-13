#!/usr/bin/env python3
import timm
import torch

import numpy as np
import os 
import sys

from PIL import Image

import torch.nn.functional as F
import torch.nn as nn

from timm.data.transforms_factory import create_transform
from timm.data import resolve_data_config

import coremltools as ct
import torchvision

image1 = "<img to compare #1>"
image2 = "<img to compare #2>"


model = timm.create_model("tiny_vit_5m_224.dist_in22k", pretrained=True).eval()
config = resolve_data_config({}, model=model)
tfms = create_transform(**config)


# # some of the code here is adapted from https://github.com/towhee-io/towhee/discussions/2215
# # this applies the expected parameters of transformation for the image

im1 = tfms(Image.open(image1))[None]
im2 = tfms(Image.open(image2))[None]


def obtain_pooled_features(features):
	global_pool = torch.nn.AdaptiveAvgPool2d(1)
	features = global_pool(features)
	features = features.flatten(1).detach()

	return features


cos = torch.nn.functional.cosine_similarity

#First test with non-modified images. Test with pooled features
#Test with non-pooled features.

# Non Pool
m1_output = model.forward_head(model.forward_features(im1), pre_logits=True)
m2_output = model.forward_head(model.forward_features(im2), pre_logits=True)
print(m1_output.shape)

cosine_result = cos(m1_output, m2_output)

print(f"Similarity for non pooled features: {cosine_result[0]}")


class ViTWrapper(nn.Module):

	def __init__(self):
		super(ViTWrapper, self).__init__()
		self.model = model = timm.create_model("tiny_vit_5m_224.dist_in22k", pretrained=True).eval()

	@torch.no_grad()	
	def forward(self, image):
		o1 = self.model.forward_features(image)
		o2 = self.model.forward_head(o1, pre_logits=True)
		return o2.squeeze()




model = ViTWrapper().eval()

config = resolve_data_config({}, model=model.model)
tfms = create_transform(**config)
print(tfms)
im1 = tfms(Image.open(image1))[None]


trace = torch.jit.trace(model, im1)


# from coreml conversion guide
scale = 1/(0.226*255.0)
bias = [- 0.485/(0.229) , - 0.456/(0.224), - 0.406/(0.225)]

image_input = ct.ImageType(name="input_1",
                           shape=im1.shape,
                           scale=scale, bias=bias)

mlmodel = ct.convert(trace,inputs=[image_input],
	minimum_deployment_target=ct.target.iOS16,
	outputs=[ct.TensorType(name="output", dtype=np.float32)],
	compute_units=ct.ComputeUnit.ALL)

mlmodel.save("TinyVit")



output1 = torch.tensor(mlmodel.predict({'input_1': Image.open(image1).resize((224,224))})['output'])
output2 = torch.tensor(mlmodel.predict({'input_1': Image.open(image2).resize((224,224))})['output'])

im1 = tfms(Image.open(image1))[None]
im2 = tfms(Image.open(image2))[None]
m1_output = model(im1)
m2_output = model(im2)
print(f"outputs 1: {m1_output.shape}; {m1_output.dtype}")
print(torch.nn.functional.cosine_similarity(m1_output, m2_output, dim=0))
print('-=-=-=-')
print(torch.nn.functional.cosine_similarity(output1, output2, dim=0))




