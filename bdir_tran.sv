
class transaction;

    // direction:
    //   1 = DUT drives the bus (output mode)
    //   0 = External device drives the bus (input mode)
    rand bit direction;

    // Value DUT will drive in output mode
    rand bit data_out;

    // Value external device will drive in input mode
    rand bit ext_data;

    // Constructor
    function new();
        direction = 0;
        data_out  = 0;
        ext_data  = 0;
    endfunction

    // Optional: print for debug
    function void display();
        $display("TX | direction=%0b | data_out=%0b | ext_data=%0b",
                 direction, data_out, ext_data);
    endfunction

endclass
