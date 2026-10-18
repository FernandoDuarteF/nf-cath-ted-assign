process CHUNKBYZIP {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/a3/a3f1df1b7ac21563fc24563abb8de5df497c50e5b7bc186b1780cb0320c1af9d/data'
        : 'community.wave.seqera.io/library/python:3.13.16--0e261d9000df13f5'}"

    input:
    tuple val(meta), path(tsv)
    val chunk_size

    output:
    tuple val(meta), path("${prefix}.tsv"), emit: tsv
    tuple val(meta), path("${prefix}/*.txt", arity: '1..*'), emit: chunk_folder
    tuple val("${task.process}"), val('python'), eval('python3 --version | sed "s/Python //"'), emit: versions_python, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    chunk_by_zip.py \\
        --input_file ${tsv} \\
        --chunk_size ${chunk_size} \\
        --outdir ${prefix} \\
        --file_list ${prefix}.tsv
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir ${prefix}
    touch ${prefix}/${prefix}_ids_mapping.0.txt
    touch ${prefix}.tsv
    """
}
