process GETUNIPROT {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/50/50faac2be6b987b749f3d58c640e57649f6c28d1754c1392c83e74635739acfa/data'
        : 'community.wave.seqera.io/library/pandas_python_requests:bc63b6490b345a7d'}"

    input:
    tuple val(meta), path(tsv)

    output:
    tuple val(meta), path("${prefix}.uniprot_data.tsv"), emit: tsv
    tuple val("${task.process}"), val('python'), eval('python3 --version | sed "s/Python //"'), emit: versions_python, topic: versions
    tuple val("${task.process}"), val('pandas'), eval('python3 -c "import pandas; print(pandas.__version__)"'), emit: versions_pandas, topic: versions
    tuple val("${task.process}"), val('requests'), eval('python3 -c "import requests; print(requests.__version__)"'), emit: versions_requests, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    fetch_uniprot_data.py \\
        ${args} \\
        --input ${tsv} \\
        --output ${prefix}.uniprot_data.tsv
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.uniprot_data.tsv
    """
}
