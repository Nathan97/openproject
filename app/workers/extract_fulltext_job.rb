#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'text_extractor'

class ExtractFulltextJob < ApplicationJob
  def initialize(attachment_id)
    @attachment_id = attachment_id
    @attachment = nil
    @text = nil
    @file = nil
    @filename = nil
    @language = OpenProject::Configuration.main_content_language
  end

  def perform
    return unless @attachment = find_attachment(@attachment_id)

    init

    if OpenProject::Database.allows_tsv?
      update
    else
      attachment.update(fulltext: @text)
    end
  end

  private

  def init
    carrierwave_uploader = @attachment.file
    @file = carrierwave_uploader.local_file
    @filename = carrierwave_uploader.file.filename
    @text = TextExtractor::Resolver.new(@file, @attachment.content_type).text if @attachment.readable?
  end

  def update
    Attachment
      .where(id: @attachment_id)
      .update_all(['fulltext = ?, fulltext_tsv = to_tsvector(?, ?), file_tsv = to_tsvector(?, ?)',
                   @text,
                   @language,
                   OpenProject::FullTextSearch.normalize_text(@text),
                   @language,
                   OpenProject::FullTextSearch.normalize_filename(@filename)])
  end

  def find_attachment(id)
    Attachment.find_by_id id
  end
end
