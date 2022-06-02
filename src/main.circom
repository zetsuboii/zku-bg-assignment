pragma circom 2.0.3;

template Multiplier2(){
   // Create input signals in1 and in2
   signal input in1;
   signal input in2;
   // Create the output signal out
   signal output out;

   // Assign product of in1 and in2 to out
   out <== in1 * in2;
   // Log the out signal
   log(out);
}

// This will make in1 and in2 public
component main {public [in1,in2]} = Multiplier2();

/* INPUT = {
    "in1": "777",
    "in2": "11S"
} */