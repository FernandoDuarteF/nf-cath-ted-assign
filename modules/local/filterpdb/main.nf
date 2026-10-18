process FILTERPDB {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/46/46924d668bf244397aff77dda82f0ff9470adc2c9396b20490e5f644688b322a/data'
        : 'community.wave.seqera.io/library/gemmi_python:dcda7813bb27249c'}"

    input:
    tuple val(meta), path(ids), path(pdb_zip)
    val min_residues
    val max_residues

    output:
    tuple val(meta), path("${prefix}.filtered_ids.txt"), emit: ids
    tuple val(meta), path("${prefix}.filter_metadata.tsv"), emit: metadata
    tuple val("${task.process}"), val('python'), eval('python3 --version | sed "s/Python //"'), emit: versions_python, topic: versions
    tuple val("${task.process}"), val('gemmi'), eval('python3 -c "import gemmi; print(gemmi.__version__)"'), emit: versions_gemmi, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    filter_pdb_zip.py \\
        ${args} \\
        --pdb-zip ${pdb_zip} \\
        --ids ${ids} \\
        --min-residues ${min_residues} \\
        --max-residues ${max_residues} \\
        --output-ids ${prefix}.filtered_ids.txt \\
        --output-metadata ${prefix}.filter_metadata.tsv
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.filtered_ids.txt
    touch ${prefix}.filter_metadata.tsv
    """
}
