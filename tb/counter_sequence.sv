// Sequence: enable for N cycles, disable, re-enable
class counter_sequence extends uvm_sequence #(counter_seq_item);
    `uvm_object_utils(counter_sequence)

    int unsigned enable_cycles   = 8;
    int unsigned disable_cycles  = 3;
    int unsigned reenable_cycles = 8;
    int unsigned idle_cycles     = 3; // final idle so DUT is quiescent at end

    function new(string name = "counter_sequence");
        super.new(name);
    endfunction

    task body();
        counter_seq_item item;
        `uvm_info("SEQ", "Starting counter_sequence", UVM_MEDIUM)

        // Phase 1: enable for enable_cycles
        item = counter_seq_item::type_id::create("item_en");
        start_item(item);
        item.enable     = 1'b1;
        item.num_cycles = enable_cycles;
        finish_item(item);
        `uvm_info("SEQ", $sformatf("Sent ENABLE for %0d cycles", enable_cycles), UVM_MEDIUM)

        // Phase 2: disable for disable_cycles
        item = counter_seq_item::type_id::create("item_dis");
        start_item(item);
        item.enable     = 1'b0;
        item.num_cycles = disable_cycles;
        finish_item(item);
        `uvm_info("SEQ", $sformatf("Sent DISABLE for %0d cycles", disable_cycles), UVM_MEDIUM)

        // Phase 3: re-enable for reenable_cycles
        item = counter_seq_item::type_id::create("item_reen");
        start_item(item);
        item.enable     = 1'b1;
        item.num_cycles = reenable_cycles;
        finish_item(item);
        `uvm_info("SEQ", $sformatf("Sent RE-ENABLE for %0d cycles", reenable_cycles), UVM_MEDIUM)

        // Phase 4: idle (enable=0) — ensures DUT is quiescent before objection drop
        // Without this, the driver holds enable at its last value during any
        // post-sequence delay in the test, causing spurious counting.
        item = counter_seq_item::type_id::create("item_idle");
        start_item(item);
        item.enable     = 1'b0;
        item.num_cycles = idle_cycles;
        finish_item(item);
        `uvm_info("SEQ", $sformatf("Sent IDLE for %0d cycles", idle_cycles), UVM_MEDIUM)

        `uvm_info("SEQ", "counter_sequence complete", UVM_MEDIUM)
    endtask
endclass
