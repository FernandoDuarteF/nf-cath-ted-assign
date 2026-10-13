include { CREATEINPUTZIP } from '../../../modules/local/createinputzip/main.nf'
include { CHUNKBYZIP } from '../../../modules/local/chunkbyzip/main.nf'
include { GETUNIPROT } from '../../../modules/local/getuniprot/main.nf'

workflow PREPARE_INPUT {

    take:
    ch_zip_file // channel: [ val(meta), [ bam ] ]

    main:

    //
    // MODULE: CREATEINPUTZIP
    //

    CREATEINPUTZIP (
        ch_zip_file
    )

    // Get the input mapping files and their corresponding meta information
    CREATEINPUTZIP.out.input_mapping
        .map { meta, tsv ->
            def splittsv = tsv.splitCsv(header:false, sep:'\t', strip:true) // Split TSV into a list of lists
            [ meta, splittsv ] // channel: [ val(meta), [ [ pdb_id, zip ] ] ]
        }
        .transpose() // Transpose to get a channel per PDB ID: [ meta, [ pdb_id, zip ] ]
        .map { meta, pdb_zip ->
            def pdb_id = pdb_zip[0]
            def zip = pdb_zip[1]
            def new_meta = meta + [ pdb_id: pdb_id ] // Add pdb_id to meta
            [ new_meta, zip ] // channel: [ val(new_meta), val(zip) ]
        }
        .filter { meta, zip -> zip && meta.pdb_id }
        .unique()
        .flatMap() // Necessary because of toSortedList output
        .set { ch_input_mapping }

    // Apply debug limit if enabled
    if (params.debug && params.max_entries) {
        ch_input_mapping
            .take(params.max_entries)
            .set { ch_input_mapping }
    }

    // Collect all input mapping files into a single TSV file
    ch_input_mapping
        .collectFile (
            sort: true,
            newLine: true,
            storeDir: "${params.outdir}/intermediate",
        ) { meta, zip ->
            [ "${meta.id}.all_ids_mapping.tsv", "${meta.pdb_id}\t${zip}" ]
        }
        .map { tsv ->
            def id = tsv.name - '.all_ids_mapping.tsv' // Remove the suffix to get the ID
            [ [ id: id ], tsv ]
        }
        .set { ch_all_ids_mapping } // channel: [ val(meta), path(tsv) ]

    //
    // MODULE: CHUNKBYZIP
    //

    // params.chunk_size PDBs per chunk
    CHUNKBYZIP (
        params.chunk_size,
        ch_all_ids_mapping
    )

    // Get the chunk files and their corresponding meta information
    CHUNKBYZIP.out.chunk_folder // channel: [ val(meta), path(chunk_files) ]
        .transpose() // Transpose to get a channel per chunk: [ val(meta), path(chunk_file) ]
        .map { meta, chunk_file ->
            def chunk_id = chunk_file.name.tokenize('.')[-2].toInteger() // Get the chunk ID from the chunk file name (0-based index)
            def new_meta = meta + [ chunk_id: chunk_id ] // Add chunk_id to meta
            [ new_meta, chunk_file ] // channel: [ val(new_meta), path(chunk_file) ]
        }
        .set { ch_chunks } // channel: [ val(meta), path(chunk_file) ]

    // Combine chunk files with their corresponding original zip files
    ch_chunks
        .map { meta, chunk_file ->
            [ meta.id, meta, chunk_file ] // channel: [ val(meta.id), val(meta), path(chunk_file) ]
        }
        .combine(
            ch_zip_file.map { meta, zip -> [ meta.id, meta, zip ] }, // Combined by meta.id (zip original file)
            by: 0
        )
        .map { _combine_col, chunk_meta, chunk_file, _zip_meta, zip_file -> // chunk_meta has all the meta info
            [ chunk_meta, chunk_file, zip_file ] // channel: [ val(chunk_meta), path(chunk_file), path(zip_file) ]
        }

    //
    // MODULE: GETUNIPROT
    //

    // Only needs ch_chunks as input
    GETUNIPROT (
        ch_chunks
    )

}
