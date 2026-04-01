// Monitor for Verilator -- covergroup REMOVED
// NOTE: covergroups inside UVM classes cannot be sampled via the standard
// UVM coverage API in the chipsalliance uvm-verilator fork.
// Workaround: remove covergroup; document as a Verilator gap in NOTES.md.
class counter_monitor extends uvm_monitor;
    `uvm_component_utils(counter_monitor)

    virtual counter_if vif;
    uvm_analysis_port #(counter_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual counter_if)::get(this, "", "vif", vif))
            `uvm_fatal("CFG", "counter_monitor: cannot get vif from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        counter_seq_item item;
        forever begin
            @(posedge vif.clk);
            item = counter_seq_item::type_id::create("mon_item");
            item.enable     = vif.enable;
            item.num_cycles = 1;
            ap.write(item);
            `uvm_info("MON", $sformatf("Observed count=0x%02h enable=%0b",
                      vif.count, vif.enable), UVM_HIGH)
        end
    endtask
endclass
