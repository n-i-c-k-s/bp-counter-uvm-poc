// Agent: bundles driver + sequencer + monitor
class counter_agent extends uvm_agent;
    `uvm_component_utils(counter_agent)

    counter_driver                  drv;
    counter_monitor                 mon;
    uvm_sequencer #(counter_seq_item) seqr;

    uvm_analysis_port #(counter_seq_item) ap; // forwarded from monitor

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv  = counter_driver::type_id::create("drv",  this);
        mon  = counter_monitor::type_id::create("mon", this);
        seqr = uvm_sequencer #(counter_seq_item)::type_id::create("seqr", this);
        ap   = new("ap", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
        mon.ap.connect(ap);
    endfunction
endclass
