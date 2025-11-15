class test;
    
    environment env;
    
    virtual bidirectional_intf vif;
    
    function new(virtual bidirectional_intf vif);
        this.vif = vif;
    endfunction
    
    task build();
        $display("Test: Building environment...");
        env = new(vif);
        env.build();
        $display("Test: Build completed");
    endtask
    
    task run();
        $display("\n=== Test: Starting ===\n");
        env.run();
        $display("\n=== Test: Completed ===\n");
    endtask
    
endclass