process GETUNIPROT {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "ghcr.io/uclorengogroup/domain-annotation-pipeline-script:${params.container_tag_name}"

    input:
    tuple val(meta), path(tsv)

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    tuple val("${task.process}"), val('python'), eval("python3 --version | cut -d' ' -f2"), topic: versions, emit: versions_getuniprot

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    fetch_uniprot_data.py \\
        $args \\
        -i ${tsv} \\
        -o ${prefix}.uniprot_data.tsv
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo $args
    
    touch ${prefix}.uniprot_data.tsv
    """
}
