#!/usr/bin/env python3
#
# takes exported np-array weights from Netron and converts to binary string files
# for use by VHDL components. could also do this direct from *.tflite file like in:
# https://stackoverflow.com/questions/52111699/how-can-i-view-weights-in-a-tflite-file
#

import numpy as np

def int_to_bin_string(value, bitWidth):
    # convert to signed-8b twos-complement value
    twos_cmplt = value & ((2**bitWidth)-1)
    # write out as padded binary string (always fixed character width)
    return str((bin(twos_cmplt)[2:].zfill(bitWidth)))

# assumes FC weights are simple 2D numpy matrix of size (output, input)
def write_FC_weight_files(weights, layerID, bitWidth):
    for node_idx in range(len(weights)):
        # write individual weight file per perceptron/neural-node
        fd = open("FC_weights_layer_%d_node_%d.txt" % (layerID, node_idx), "w")
        for weight_val in weights[node_idx]:
            fd.write( int_to_bin_string(weight_val, bitWidth) + "\n" )
        fd.close()


if __name__ == "__main__":
    # execute only if run as a script
    nBits    = 8  # bitwidth of quantized integer weights
    layerIdx = 0  # layer index to help identify sets of weight files

    # Netron easily export layer weights directly as NumPy array files
    conv2D_weights = np.load("./sequential_conv2d_0")
    FC0_weights    = np.load("./sequential_dense_MatMul_FC0")
    FC1_weights    = np.load("./sequential_dense_MatMul_FC1")

    print("\tLayer 0: 2D convolution weights of size {}".format(conv2D_weights.shape))
    print("Fully-connected dimensions = (output, input)")
    print("\tLayer 1: Fully-connected weights of size {}".format(FC0_weights.shape))
    print("\tLayer 2: Fully-connected weights of size {}".format(FC1_weights.shape))

    write_FC_weight_files(FC0_weights, layerIdx, nBits)
    layerIdx += 1
    write_FC_weight_files(FC1_weights, layerIdx, nBits)


