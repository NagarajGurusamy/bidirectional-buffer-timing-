class environment;
    
    driver drv;
    monitor mon;
    scoreboard scb;
    
    virtual bidirectional_intf vif;
    
    function new(virtual bidirectional_intf vif);
        this.vif = vif;
    endfunction
    
    task build();
        $display("Environment: Building components...");
        drv = new(vif);
        mon = new(vif);
        scb = new(vif);
        $display("Environment: Build completed");
    endtask
    
    task run();
        $display("Environment: Starting simulation...");
        
        fork
            mon.run();
            scb.run();
        join_none
        
        drv.run();
        
        #50;
        
        scb.report();
        
        $display("Environment: Simulation completed");
    endtask
    
endclass