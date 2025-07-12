// import your collection into the scope of the file
use ::{CustomGraph, CustomGIR};
// each macro creates entire test suite for the specific
// implementer of the algorithm
test_graph!(CustomGraph, custom_graph);
test_gir!(CustomGIR, custom_gir);
