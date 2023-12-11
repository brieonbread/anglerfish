module tm_choice (
  input wire [7:0] data_in,
  output logic [8:0] qm_out
  );

  logic [3:0] one_count;
  logic [8:0] qm1;
  logic [8:0] qm2;

  always_comb begin
    one_count = data_in[7] + data_in[6] + data_in[5] + data_in[4] + data_in[3] + data_in[2] + data_in[1] + data_in[0];
    qm1[0] = data_in[0];
    qm2[0] = data_in[0];
    for (int i = 1; i < 8; i = i + 1) begin
      qm1[i] = data_in[i] ^ qm1[i - 1];
      qm2[i] = ~(data_in[i] ^ qm2[i - 1]);
    end
    qm1[8] = 1;
    qm2[8] = 0;
    qm_out = ((one_count > 4) || ((one_count == 4) && (data_in[0] == 0)))? qm2 : qm1;
  end

endmodule //end tm_choice
