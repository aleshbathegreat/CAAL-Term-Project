#include <iostream>
#include <random>

using namespace std;

const int signal_length = 8;
double frequency_vector [signal_length];

double signals [signal_length];
double twiddle_factor[signal_length/2];

void fft(double* a, int size) {
    if (size == 1) return;

    double a_even [size/2];
    double a_odd [size/2];

    for (int i = 0; i < size/2; ++i) {
        a_even[i] = a[i];
        a_odd[i] = a[i + size/2];
    }

    fft(a_even, size/2);
    fft(a_odd, size/2);

    for (int k = 0; 2*k < size; ++k) {
        a[k] = a_even[k] + twiddle_factor[k] * a_odd[k];
        a[k + size/2] = a_even[k] - twiddle_factor[k] * a_odd[k];
    }
}


int main() {

    mt19937 gen(123);
    uniform_real_distribution<> dist(-1.0, 1.0);

    for (auto& signal: signals) {
        signal = dist(gen);
    }
    //bitreversal(signals)
    for (int i =0 ; i<signal_length/2; i++) {
        twiddle_factor[i] = 1;
    }
    for (int i =0 ; i<signal_length; i++) {
        std::cout << signals[i] << endl;
    }
    fft(signals,signal_length);
    std::cout<<endl;
    for (int i =0 ; i<signal_length; i++) {
        std::cout << signals[i] << endl;
    }

    return 0;
}
