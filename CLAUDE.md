# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository is a Korean-language research report for developing an early dementia diagnosis AI system (`치매_AI진단_조사보고서.md`). It documents datasets, model approaches, and implementation guidance — there is no executable code or build system.

## Document Structure

The report covers four areas:

1. **Korean Public Data Sources** — National dementia center data and long-term care facility info via data.go.kr
2. **AI Hub Datasets** — Two restricted datasets (Korean nationals only via AI Hub safe zone):
   - Dementia Diagnostic Medical Imaging (~7,100 MRI/PET cases with FreeSurfer ROI annotations, CERAD-K/SNSB clinical data)
   - Dementia Diagnostic Brain MRI (~280,000 images from 780 patients, labeled ADD/aMCI/NC)
3. **Model Development Guide** — Preprocessing pipeline (DICOM→NIfTI→skull strip→MNI152 registration), model selection table (3D ResNet/DenseNet, EfficientNet, ViT, SwinTransformer 3D), evaluation metrics (AUC-ROC target ≥0.95, Sensitivity, F1)
4. **Reference Links** — URLs for data.go.kr, aihub.or.kr datasets, and MONAI documentation

## Technology Stack (Referenced, Not Implemented)

- **PyTorch + torchvision** — primary deep learning framework
- **MONAI** — recommended medical imaging library (strongly preferred over raw PyTorch for MRI workflows)
- **nibabel / nilearn** — NIfTI/DICOM I/O and brain image preprocessing
- **FreeSurfer** — brain region segmentation
- **scikit-learn / matplotlib** — evaluation and visualization

The report recommends starting with a 2D CNN slice-based baseline (ResNet50) before moving to 3D or multimodal approaches.
