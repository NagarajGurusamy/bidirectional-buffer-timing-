
interface bidirectional_intf;
    
    logic data_line;
    logic direction;
    logic data_out;
    logic data_in;
    
    modport dut_port (
        inout data_line,
        input direction,
        input data_out,
        output data_in
    );
    
    modport tb_port (
        inout data_line,
        output direction,
        output data_out,
        input data_in
    );
    
endinterface