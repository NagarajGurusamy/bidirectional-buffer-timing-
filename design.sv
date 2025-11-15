module bidirectional_port (
    inout wire data_line,
    input wire direction,
    input wire data_out,
    output wire data_in
);

    assign data_line = direction ? data_out : 1'bz;
    assign data_in = data_line;

endmodule