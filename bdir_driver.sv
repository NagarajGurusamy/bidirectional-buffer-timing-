class driver;
    
    virtual bidirectional_intf vif;
    
    function new(virtual bidirectional_intf vif);
        this.vif = vif;
    endfunction
    
    task drive_output(input logic data);
        vif.direction = 1;
        vif.data_out = data;
        #10;
    endtask
    
    task drive_input(input logic data);
        vif.direction = 0;
        vif.data_out = 0;
        #10;
    endtask
    
    task run();
        $display("Driver: Starting...");
        
        drive_output(0);
        $display("Time=%0t | Driver: Output mode, data_out=0", $time);
        
        drive_output(1);
        $display("Time=%0t | Driver: Output mode, data_out=1", $time);
        
        drive_input(0);
        $display("Time=%0t | Driver: Input mode", $time);
        
        drive_input(1);
        $display("Time=%0t | Driver: Input mode", $time);
        
        $display("Driver: Completed");
    endtask
    
endclass