const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class ClinicalRecord extends Model {}

  ClinicalRecord.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    appointment_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    notes_text: {
      type: DataTypes.TEXT
    },
    prescription_text: {
      type: DataTypes.TEXT
    },
    prescription_file_url: {
      type: DataTypes.STRING(500)
    },
    risk_indicator: {
      type: DataTypes.STRING(20),
      defaultValue: 'low'
    }
  }, {
    sequelize,
    modelName: 'ClinicalRecord',
    tableName: 'clinical_records',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
  });

  ClinicalRecord.associate = (models) => {
    ClinicalRecord.belongsTo(models.Appointment, {
      foreignKey: 'appointment_id',
      as: 'appointment'
    });
  };

  return ClinicalRecord;
};
