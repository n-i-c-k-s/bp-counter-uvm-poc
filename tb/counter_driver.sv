// Driver: drives enable signal onto the DUT interface
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
        vif.driver_cb.rst_n  <= 1'b0;
        vif.driver_cb.enable <= 1'b0;
        repeat(3) @(vif.driver_cb);
        vif.driver_cb.rst_n <= 1'b1;
        @(vif.driver_cb);

        forever begin
            seq_item_port.get_next_item(item);
            `uvm_info("DRV", $sformatf("Driving: %s", item.convert2string()), UVM_MEDIUM)
            repeat(item.num_cycles) begin
                vif.driver_cb.enable <= item.enable;
                @(vif.driver_cb);
            end
            seq_item_port.item_done();
        end
    endtask
endclass
