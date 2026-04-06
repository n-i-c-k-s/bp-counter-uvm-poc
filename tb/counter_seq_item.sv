// Sequence item: carries one transaction (enable for N cycles)
class counter_seq_item extends uvm_sequence_item;
    `uvm_object_utils(counter_seq_item)

    rand bit       enable;
    rand int unsigned num_cycles; // how many cycles to hold enable

    constraint reasonable_cycles { num_cycles inside {[1:16]}; }

    function new(string name = "counter_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("enable=%0b num_cycles=%0d", enable, num_cycles);
    endfunction
endclass
