#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <iostream>
#include <math.h>

// kernel function to add elements of two arrays
__global__
void add(int n, float *x, float *y) {
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < n; i += stride)
        y[i] = x[i] + y[i];
}

int main(void) {

    int N = 1 << 20;
    float *x, *y;

    // allocate unified memory (cpu & gpu)
    cudaMallocManaged(&x, N * sizeof(float));
    cudaMallocManaged(&y, N * sizeof(float));

    // initialise x and y arrays on host
    for (int i = 0; i < N; i++) {
        x[i] = 1.0f;
        y[i] = 2.0f;
    }

    // prefetch x and y arrays to the gpu
    cudaMemPrefetchAsync(x, N * sizeof(float), 0, 0);
    cudaMemPrefetchAsync(y, N * sizeof(float), 0, 0);

    // run kernel on 1 million elements on gpu
    int blockSize = 256;
    int numBlocks = (N + blockSize - 1) / blockSize;
    add<<<numBlocks, blockSize>>>(N, x, y);

    // wait for gpu to finish before accessing host
    cudaDeviceSynchronize();

    // error checking (all values should be 3.0f)
    float maxError = 0.0f;
    for (int i = 0; i < N; i++)
        maxError = fmax(maxError, fabs(y[i] - 3.0f));
    std::cout << "Max error: " << maxError << std::endl;

    // free memory
    cudaFree(x);
    cudaFree(y);

    return 0;
}