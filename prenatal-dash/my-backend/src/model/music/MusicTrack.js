const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class MusicTrack extends Model {}

  MusicTrack.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    title_en: {
      type: DataTypes.STRING(500)
    },
    title_am: {
      type: DataTypes.STRING(500)
    },
    title_om: {
      type: DataTypes.STRING(500)
    },
    title_so: {
      type: DataTypes.STRING(500)
    },
    category: {
      type: DataTypes.STRING(100),
      allowNull: false
    },
    duration_seconds: {
      type: DataTypes.INTEGER
    },
    image_url: {
      type: DataTypes.STRING(500)
    },
    audio_en_url: {
      type: DataTypes.STRING(500)
    },
    audio_am_url: {
      type: DataTypes.STRING(500)
    },
    audio_om_url: {
      type: DataTypes.STRING(500)
    },
    audio_so_url: {
      type: DataTypes.STRING(500)
    },
    description_en: {
      type: DataTypes.TEXT
    },
    description_am: {
      type: DataTypes.TEXT
    },
    description_om: {
      type: DataTypes.TEXT
    },
    description_so: {
      type: DataTypes.TEXT
    },
    benefits_en: {
      type: DataTypes.TEXT
    },
    benefits_am: {
      type: DataTypes.TEXT
    },
    benefits_om: {
      type: DataTypes.TEXT
    },
    benefits_so: {
      type: DataTypes.TEXT
    },
    is_featured: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    display_order: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    }
  }, {
    sequelize,
    modelName: 'MusicTrack',
    tableName: 'music_tracks',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  return MusicTrack;
};
