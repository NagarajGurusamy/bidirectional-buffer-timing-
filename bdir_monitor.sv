class monitor;
    
    virtual bidirectional_intf vif;
    
    function new(virtual bidirectional_intf vif);
        this.vif = vif;
    endfunction
    
    task run();
        $display("Monitor: Starting...");
        
        forever begin
            @(vif.direction or vif.data_out or vif.data_line or vif.data_in);
            #1;
            $display("Time=%0t | Monitor: direction=%b | data_out=%b | data_line=%b | data_in=%b", 
                     $time, vif.direction, vif.data_out, vif.data_line, vif.data_in);
        end
    endtask
    
endclass