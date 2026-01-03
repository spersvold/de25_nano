/* Chain Description File for the DE25-Nano on-board QSPI flash.
 * Consumed by quartus_pgm to JTAG-program the .jic.
 *
 * Cable 1 is the on-board USB-Blaster (jtagconfig --list to verify).
 */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Cfg)
		Device PartName(A5EB013BB23BE4SCS) Path("output_files/") File("de25_nano_hps.jic") MfrSpec(OpMask(1) SEC_Device(MT25QU128) Child_OpMask(1 1));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
	Frequency(16000000);
AlteraEnd;
