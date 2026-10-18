process CREATEINPUTZIP {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/a3/a3f1df1b7ac21563fc24563abb8de5df497c50e5b7bc186b1780cb0320c1af9d/data'
        : 'community.wave.seqera.io/library/python:3.13.16--0e261d9000df13f5'}"

    input:
    tuple val(meta), path(zip)

    output:
    tuple val(meta), path("${prefix}_input_mapping.tsv"), emit: input_mapping
    tuple val("${task.process}"), val('python'), eval('python3 --version | sed "s/Python //"'), emit: versions_python, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    create_input_from_zip_script.py \\
        --input_zip_dir . \\
        --output ${prefix}_input_mapping.tsv
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_input_mapping.tsv
    """
}
