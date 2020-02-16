# TemporalLabelingGUI

This code allows for accurate manual labeling of neuron activity from calcium imaging videos using a graphic user interface (GUI). The adaptation of this software to existing data provides a means of training a neural network algorithm for automatically segmenting active neurons.

### System Requirements 
* MATLAB 2017b and MATLAB Runtime version 9.3
  * Neural Network Toolbox, Image Processing Toolbox, and the [GUI Layout Toolbox][gui-toolbox]
  * MATLAB Runtime can be acquired from [here][runtime-link]
  
[gui-toolbox]: https://www.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox

### Preparing Data
Imaging data should include a video as a nifti file (.nii or .nii.gz) with masks as a .mat file. Once the code is downloaded and setup in MATLAB, load the video and masks as arrays using load('MASKS FILE NAME HERE') and vid=niftiread('VIDEO FILE NAME HERE').

### Functionality
To run the GUI, run NeuroFilter(VIDEO ARRAY VARIABLE NAME HERE, MASKS ARRAY VARIABLE NAME HERE).

To add labels for each neuron, follow the following steps in order:
* Select Spike - Select "Select Spike" to add labels for each spike of activity. After clicking "Select Spike", the software will play a video of the first spike of activity, if active. 
* Yes Spike/No Spike - Click "Yes Spike" or "No Spike" to label the first spike. The software will continue to prompt the user to label each spike for the neuron in question.

Other options: 
* Play Video - Click "Play Video" to watch the video of the selected neuron.
* Replay Spike Video - To replay the video for a selected spike, select "Replay Spike Video". This will only work if a spike of a neuron is selected using either the "Select Spike" button, which will select the first spike of the neuron, or the "Yes Spike/No Spike" such that the program advances to select the next spike.  
* Forward Neuron/Backward Neuron - To change neurons, click "Forward Neuron" to move forward 1 neuron or "Backward Neuron" to move backward 1 neuron. The software will then update the trace for the selected neuron.
* Save Changes - To save any labels made by the user, select "Save Changes". The labels will be saved to the file "out.txt" (will be created in the same directory as the file "NeuronFilter.m". Selecting this option will also close the interface. Closing the interface without selecting "Save Changes" will lose labeling data.

Example Output:
 output{1} = [314 324 1;618 631 0;881 900 0;1567 1588 1;];
 output{2} = [1 2 1;];
 output{3} = [1 11 0;472 476 0;479 486 1;1495 1499 1;];

The output is formatted such that in each line, it first prints the neuron number, followed by an array with each element consisting of the spike start time, end time, and yes/no spike. The following formatting corresponds to the provided sample input:
 output{Neuron Number} = [StartSpikeTime EndSpikeTime YesSpike/NoSpike;]
