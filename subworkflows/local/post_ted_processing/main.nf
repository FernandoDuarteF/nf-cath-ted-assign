include { CHOPPDBZIP    } from '../../../modules/local/choppdbzip/main'
include { CHUNKSMD5     } from '../../../modules/local/chunksmd5/main'

workflow POST_TED_PROCESSING {

    take:
    ch_consensus // channel: [ val(meta), [ txt ] ]
    ch_structures // channel: [ val(meta), path(ids), path(zip) ]

    main:
    
    ch_consensus
        .join(ch_structures.map { meta, _ids, zip -> [ meta, zip ] })
        set { ch_choppdbzip }


    CHOPPDBZIP (
        ch_choppdbzip
    )

    CHUNKSMD5 (
        CHOPPDBZIP.out.pdb
    )

    // Collect md5 into a single file

}
