// Driver for Verilator — uses @(posedge vif.clk) instead of clocking block refs
class counter_driver extends uvm_driver #(counter_seq_item);
    `uvm_component_utils(counter_driver)

    virtual counter_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual counter_if)::get(this, "", "vif", vif))
            `uvm_fatal("CFG", "counter_driver: cannot get vif from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        counter_seq_item item;
        // Hold reset for 3 cycles at startup
        vif.rst_n  = 1'b0;
        vif.enable = 1'b0;
        repeat(3) @(posedge vif.clk);
        vif.rst_n = 1'b1;
        @(posedge vif.clk);

        forever begin
            seq_item_port.get_next_item(item);
            `uvm_info("DRV", $sformatf("Driving: enable=%0b num_cycles=%0d",
                      item.enable, item.num_cycles), UVM_MEDIUM)
            repeat(item.num_cycles) begin
                vif.enable = item.enable;
                @(posedge vif.clk);
            end
            seq_item_port.item_done();
        end
    endtask
endclass
