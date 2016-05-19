# An extension of the ActiveAnnotations gem to include Avalon specific information in the Annotation
# Sets defaults for the annotation using information from the master_file and includes solrization of the annotation
# @since 5.0.0
class AvalonAnnotation < ActiveAnnotations::Annotation
  after_save :post_to_solr
  after_destroy :delete_from_solr
  before_save :validate_times

  attr_accessor :master_file

  alias_method :comment, :content
  alias_method :comment=, :content=

  alias_method :title, :label
  alias_method :title=, :label=

  validates :start_time, numericality: true
  validates :end_time, numericality: true

  after_initialize do
    self.source = master_file unless master_file.nil?
    selector_default!
    title_default!
  end

  # Mixs in in Avalon specific information from the master_file to a rdf annonation prior and creates a solr document
  # @return [Hash] a hash capable of submission to solr
  def to_solr
    solr_hash = {}
    # TODO: User Key via parsing of User URI
    #byebug
    solr_hash[:id] = solr_id
    solr_hash[:title_ssi] = title
    solr_hash[:master_file_uri_ssi] = master_file.rdf_uri
    solr_hash[:master_file_rdf_type_ssi] = master_file.rdf_type
    solr_hash[:start_time_fsi] = start_time
    solr_hash[:end_time_fsi] = end_time
    solr_hash[:mediafragment_uri_ssi] = mediafragment_uri
    solr_hash[:comment_ssi] = comment unless comment.nil?
    solr_hash[:referenced_source_type_ssi] = 'MasterFile'
    solr_hash[:reference_type_ssi] = 'MediaFragment'
    solr_hash
  end

  # Solrize the Avalon Annotation in the application's solr core
  def post_to_solr
    ActiveFedora::SolrService.add(to_solr, softCommit: true)
  end

  # Delete the solr document of an Avalon Annotation that has been deleted
  def delete_from_solr
    ActiveFedora::SolrService.instance.conn.delete_by_id(solr_id, softCommit: true)
  end

  # Find the annotation's position on a playlist
  # This returns with 1, not 0, as the array start point due to the acts as order gems used on playlist item
  # @param [Int] playlist_id The ID of the playlist
  # @return [Int] the position
  # @return [Nil] if the annotation is not on the specified playlist
  def playlist_position(playlist_id)
    p_item = PlaylistItem.where(playlist_id: playlist_id, annotation_id: id)[0]
    return p_item if p_item.nil?
    p_item['position']
  end

  # Return the uuid of an active annotaton, with the urn:uuid removed
  # @return [String] the uuid of the annotation
  def solr_id
    uuid.split(':').last
  end

  # Sets the default selector to a start time of 0 and an end time of the master file length
  def selector_default!
    self.start_time = 0 if self.start_time.nil?
    self.end_time = (master_file.duration || 1) if self.end_time.nil?
  end

  # Set the default title to be the label of the master_file
  def title_default!
    self.title = master_file.embed_title if self.title.nil?
  end

  # Sets the class variable @master_file by finding the master referenced in the source uri
  def master_file
    @master_file ||= MasterFile.find(source.split('/').last)
  end

  def master_file=(value)
    @master_file = value
  end

  # Calcuates the mediafragment_uri based on either the internal fragment value or start and end times
  # @return [String] the uri with time bounding
  def mediafragment_uri
    master_file.rdf_uri + "?#{internal.fragment_value.object}"
  rescue
    master_file.rdf_uri + "?t=#{start_time},#{end_time}"
  end

  def duration
    duration = (end_time-start_time)/1000
    Time.at(duration).utc.strftime(duration<3600?'%M:%S':'%H:%M:%S')
  end

  def validate_times
    master_file.reload unless master_file.nil?
    master_file = MasterFile.find( self.source.split('/').last) if master_file.nil?
    raise ArgumentError, 'Times cannot be negative numbers' if start_time < 0 || end_time < 0
    raise ArgumentError, 'End Time must be greater than Start Time' if end_time <= start_time
    raise ArgumentError, "End Time cannot exceed the source file's duration" if !master_file.duration.nil? && end_time > master_file.duration.to_f
  end
end