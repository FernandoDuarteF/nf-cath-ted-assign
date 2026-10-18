process RENUMBERPDB {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/46/46924d668bf244397aff77dda82f0ff9470adc2c9396b20490e5f644688b322a/data'
        : 'community.wave.seqera.io/library/gemmi_python:dcda7813bb27249c'}"

    input:
    tuple val(meta), path(ids), path(pdb_zip)

    output:
    tuple val(meta), path("${prefix}.normalised.zip"), emit: zip
    tuple val(meta), path("${prefix}.resmaps.zip"), emit: resmaps
    tuple val(meta), path("${prefix}.renumber_errors.tsv"), emit: errors
    tuple val("${task.process}"), val('python'), eval('python3 --version | sed "s/Python //"'), emit: versions_python, topic: versions
    tuple val("${task.process}"), val('gemmi'), eval('python3 -c "import gemmi; print(gemmi.__version__)"'), emit: versions_gemmi, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    renumber_pdb.py \\
        --input_zip ${pdb_zip} \\
        --id_file ${ids} \\
        --normalised_zip ${prefix}.normalised.zip \\
        --resmaps_zip ${prefix}.resmaps.zip \\
        --error_file ${prefix}.renumber_errors.tsv
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.normalised.zip
    touch ${prefix}.resmaps.zip
    touch ${prefix}.renumber_errors.tsv
    """
}
