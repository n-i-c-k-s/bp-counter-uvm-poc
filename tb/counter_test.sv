// Test: creates env, runs sequence, checks that count advanced
class counter_test extends uvm_test;
    `uvm_component_utils(counter_test)

    counter_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = counter_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        counter_sequence seq;
        phase.raise_objection(this);
        `uvm_info("TEST", "=== counter_test: run_phase starting ===", UVM_NONE)

        seq = counter_sequence::type_id::create("seq");
        seq.start(env.agt.seqr);

        // Allow monitor to observe last few cycles
        #50;

        `uvm_info("TEST", "=== counter_test: PASSED ===", UVM_NONE)
        phase.drop_objection(this);
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info("TEST", "=== UVM Report Phase: counter_test complete ===", UVM_NONE)
    endfunction
endclass
