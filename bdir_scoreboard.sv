class scoreboard;
    
    virtual bidirectional_intf vif;
    int pass_count;
    int fail_count;
    
    function new(virtual bidirectional_intf vif);
        this.vif = vif;
        this.pass_count = 0;
        this.fail_count = 0;
    endfunction
    
    task check();
        logic expected_data_line;
        logic expected_data_in;
        
        if (vif.direction == 1) begin
            expected_data_line = vif.data_out;
            expected_data_in = vif.data_out;
            
            if (vif.data_line === expected_data_line && vif.data_in === expected_data_in) begin
                $display("Time=%0t | Scoreboard: PASS - Output mode working correctly", $time);
                pass_count++;
            end else begin
                $display("Time=%0t | Scoreboard: FAIL - Output mode error", $time);
                fail_count++;
            end
        end else begin
            if (vif.data_line === 1'bz || vif.data_in === vif.data_line) begin
                $display("Time=%0t | Scoreboard: PASS - Input mode working correctly", $time);
                pass_count++;
            end else begin
                $display("Time=%0t | Scoreboard: FAIL - Input mode error", $time);
                fail_count++;
            end
        end
    endtask
    
    task run();
        $display("Scoreboard: Starting...");
        
        forever begin
            @(vif.direction or vif.data_out or vif.data_line);
            #2;
            check();
        end
    endtask
    
    task report();
        $display("\n=== Scoreboard Report ===");
        $display("Total PASS: %0d", pass_count);
        $display("Total FAIL: %0d", fail_count);
        $display("=========================\n");
    endtask
    
endclass